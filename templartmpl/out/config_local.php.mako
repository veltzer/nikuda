<?php
/*
 * Here is the php site configuration for nikuda
 * ${tdefs.messages_dne}
 */
$db_host=${tdefs.to_php(tdefs.nikuda_local_db_host)};
$db_user=${tdefs.to_php(tdefs.nikuda_local_db_user)};
$db_pass=${tdefs.to_php(tdefs.nikuda_local_db_password)};
$db_name=${tdefs.to_php(tdefs.nikuda_local_db_name)};
$db_port=${tdefs.to_php(tdefs.nikuda_local_db_port)};
$db_socket=${tdefs.to_php(tdefs.nikuda_local_db_socket)};
$db_charset='utf8';
$do_log_errors=true;
$do_ob=true;
$do_utf_headers=true;
$utf_charset='utf-8';
$do_error_handling=true;
$do_set_charset=true;
?>
