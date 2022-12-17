<?php
/**
 * This file recreates itself every time it is called.  It is meant to test php-fpm's opcache
 * is serving the most current version of the file.  It does so by destroying itself and
 * recreating itself every time, toggling between 'foo' or 'bar' for VALUE.
 * When php-fpm's opcache is not working properly, the caller will see a result of just 'foo'
 * or just 'bar' over and over again.
 */
define('VALUE', "bar");
if (posix_geteuid() !== fileowner(__FILE__)) {
    echo "You must be the owner of this file to execute it";
    die(1);
}
# ensure the file has the correct permissions
chmod(__FILE__, 0600);
$fp = fopen(__FILE__, 'r');
$new_file_contents = '';
while (!feof($fp)) {
    $line = fgets($fp, 1000);
    if (preg_match("/^define\('VALUE'/", $line)) {
        $is_foo = (false !== strpos($line, 'foo'));
        $line = 'define(\'VALUE\', "'.($is_foo ? 'bar' : 'foo').'");'."\n";
    }
    $new_file_contents .= $line;
}
fclose($fp);
// Recreate this file with the new contents.
file_put_contents(__FILE__, $new_file_contents)
    || die(sprintf("The permissions on the file '%s' are incorrect'", __FILE__));

echo VALUE."\n";
