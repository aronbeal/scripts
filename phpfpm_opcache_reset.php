<?php
/**
 * Resets the php-fpm opcache and apcu cache.  This is meant to be called from php-fpm, not directly
 * from php.
 * This is currently local only, and cannot (yet) be executed from the production container.
 */
apcu_clear_cache();
opcache_reset();
