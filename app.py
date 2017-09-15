import webapp2
import json
import logging
from google.appengine.ext import ndb

class Diacritics(ndb.Model):
    raw = ndb.StringProperty()
    possible_diacritics = ndb.StringProperty(repeated=True)

class CatchAll(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write('This is '+self.__class__.__name__+", "+self.request.path)


class Suggest(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write('This is '+self.__class__.__name__)
    def post(self):
        obj = json.loads(self.request.body)
        p_naked = obj['Naked']
        p_id = obj['ID']
        # the unicode letter at the end of the next line is "taf" in hebrew
        query = Diacritics.query(Diacritics.raw >= p_naked, Diacritics.raw <= p_naked + u'\u05EA')
        results = query.fetch(10)
        raw_results = [result.raw for result in results]
        obj['Nakeds'] = raw_results
        jsonstring = json.dumps(obj)
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write(jsonstring)


class Naked(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write('This is '+self.__class__.__name__)
    def post(self):
        jsonobject = json.loads(self.request.body)
        for obj in jsonobject:
            p_naked = obj['Naked']
            p_id = obj['ID']
            query = Diacritics.query(Diacritics.raw == p_naked)
            results = query.fetch()
            assert len(results) <= 1
            if len(results) == 1:
                obj['Nikudim'] = results[0].possible_diacritics
            else:
                obj['Nikudim'] = []
        jsonstring = json.dumps(jsonobject)
        self.response.headers['Content-Type'] = 'text/plain'
        self.response.write(jsonstring)

app = webapp2.WSGIApplication(
    [
        ('/app/naked', Naked),
        ('/app/suggest', Suggest),
        ('.*', CatchAll),
    ],
    debug=False,
)

def main():
    from paste import httpserver
    httpserver.serve(app, host='127.0.0.1', port='8080')

if __name__ == '__main__':
    main()
