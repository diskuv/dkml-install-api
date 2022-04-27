# Application Manifest

On Windows 10 and 11 we want setup.exe (the setup-proxy), when downloaded from
the Internet, to open a UTF-8 terminal windows. Without a manifest we can
get garbled output from ANSI escape sequences and any UTF-8 characters.

A manifest sets the use of a UTF-8 code page as per
https://docs.microsoft.com/en-us/windows/apps/design/globalizing/use-utf8-code-page

It also sets the version of the application.
