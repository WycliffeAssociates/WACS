# Gitea - WACS UI customizations

This project is UI customizations for WA's Gitea instance.

# token-trigger.sql

This file includes a trigger to add default scopes to unscoped tokens. BTT-Writer makes an API call without a scope, and gitea as of 1.21 will create the token with a null scope, so this trigger adds the appropriate scope to the token.

This should be run as soon as gitea has fully started up and finished any migrations it needs to do.

### Reference
 - https://github.com/go-gitea/gitea/pull/24767
 - https://github.com/go-gitea/gitea/issues/28820

