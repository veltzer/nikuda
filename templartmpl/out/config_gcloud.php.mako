<?php
/*
 * Here is the php site configuration for nikuda
 * ${attr.messages_dne}
 */
$db_host=empty('${attr.nikuda_gcloud_internal_db_host}') ? null : '${attr.nikuda_gcloud_internal_db_host}';
$db_user=empty('${attr.nikuda_gcloud_internal_db_user}') ? null : '${attr.nikuda_gcloud_internal_db_user}';
$db_pass=empty('${attr.nikuda_gcloud_internal_db_password}') ? null : '${attr.nikuda_gcloud_internal_db_password}';
$db_name=empty('${attr.nikuda_gcloud_internal_db_name}') ? null : '${attr.nikuda_gcloud_internal_db_name}';
$db_port=empty('${attr.nikuda_gcloud_internal_db_port}') ? null : '${attr.nikuda_gcloud_internal_db_port}';
$db_socket=empty('${attr.nikuda_gcloud_internal_db_socket}') ? null : '${attr.nikuda_gcloud_internal_db_socket}';
$db_charset='utf8';
$do_log_errors=false;
$do_ob=false;
$do_utf_headers=false;
$utf_charset='utf-8';
$do_error_handling=false;
$do_set_charset=false;
?>
