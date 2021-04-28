
----------------------------------------------
PingFederate Configuration Migration Templates
----------------------------------------------

PingFederate provides a configuration-migration tool that can be used for
scripting the transfer of administrative-console settings and configuration
files from one PingFederate server to another--for example, from a test
environment to production. The tool, configcopy[.sh|.bat] is located in the
installation's bin/ directory and may also be used for certificate management
at the target PingFederate server.

An administrator can use configcopy with any of the properties-file templates
in this directory. These files contain placeholder properties related to each of
the commands supported by configcopy.

Note that configcopy may be used with command-line property arguments, rather
than properties files. These templates are provided for administrators who wish
to use properties files, especially for scripting complex tasks.

Overrides
----------------------

NOTE: Values set for any of the "Override Properties" in these templates
will be reflected at the target server *only* if the source configuration has
the corresponding properties set; for example, if no Base URL is set in a
source connection, you cannot use this tool to set that property in the target
connection.

CAUTION: If you do set an override property that does not exist in the
source, you may experience unexpected behavior, including loss of data.

When no value is entered for an override property, then the source value
(if any) is used at the target.

For More Information
----------------------
For further information, including important instructions for using the tool,
see the "System Administration" chapter in the PingFederate "Administrator's
Manual."


Commands and Templates
----------------------

The "cmd" parameter defines the operation and can have one of the values listed
below.  Except as indicated, each of the commands is associated with a template
of the same name in this directory.

   copyconnection (default)
   listconnections
   copyallconnections

   copyadapter
   listadapters
   copyalladapters

   copyserversettings

   copydatasource
   listdatasources
   copyalldatasources

   copyprovisioningchannel
   listprovisioningchannels
   copyallprovisioningchannels

   copytokentranslator
   listtokentranslators
   copyalltokentranslators

   copytrustedcas
   listtrustedcas
   copyalltrustedcas

   listtargetkeyaliases
   createcert
   createcsr
   uploadsignedcert
   uploadpkcs12

   exportconfigarchive
   importconfigarchive

   copyfiles

      NOTE: The copyfiles command is employed in the following templates,
      which are named by use cases:

      copydeploymentconfigfiles.conf
      copyhypersonicdbs.conf
      copyclustersettings.conf

Note that, except for key aliases, the list commands above apply
only to the source configuration and most may be used with filters, as
indicated in the templates.

Two additional properties templates are provided to define the source and/or
target PingFederate servers for all commands (see the next section, "Usage"):

   source.conf
   target.conf


Usage
-----

When these templates are used, at minimum the source.conf and target.conf
templates must be configured in addition to one or more command
templates.  Copy the template files as needed to a convenient location for use
when running configcopy scripts. Then enter values as needed.

IMPORTANT: Before migrating data configured with the source PingFederate
server's administrative console using the configcopy tool, you must first copy
the key from the pf.jwk file on the source server and append it to the last key
in the pf.jwk file on the target server, and then restart that target server.
It is possible to have more than one key on the source server; if that is the
case, you copy them all. This step only needs to be done before the first
migration. For more information about copying the key from the source to the
target server, see "Copying the Key from Source to Target Server" in the
PingFederate Administrator's Manual.

To run the utility with instances of one or more properties files,
use this command:

    [Linux/Unix]
       ./configcopy.sh -Dconfigcopy.conf.file=<path_to_file>:<path_to_file>:...

    [Windows]
       configcopy.bat -Dconfigcopy.conf.file=<path_to_file>;<path_to_file>;...

    NOTE: On Windows, path designations may *not* use reverse slashes (\).
    Use forward slashes (/) or double reverse slashes (\\) instead.

IMPORTANT: On Windows, due to certain limitations, configcopy.bat may fail
if the Pingfederate server is running with Java 1.5. To avoid this issue,
ensure that you run configcopy.bat from either the installation's
../pingfederate folder or from ../pingfederate/bin.


Example:

To copy a single connection on Unix, from the bin/ directory:

    ./configcopy.sh
        -Dconfigcopy.conf.file=source.conf:target.conf:copyconnection.conf


Obfuscating Passwords
---------------------

Values for all password properties in these templates may be obfuscated
using one the following utilities in the bin/ directory:

     On Windows:
       obfuscate.bat <password>

     On Linux:
       ./obfuscate.sh <password>

Example:

     obfuscate.bat secret
       Result:
       OBF:JWE:eyJhbGciOiJkaXIiLCJlbmMiOiJBMTI4Q0JDLUhTMjU2Iiwia2lkIjoiRWN0YkRLRWpveCIsInZlcnNpb24iOiI3LjEuMjAwLjQtU05BUFNIT1QifQ..lBLVkhcOgDI_9NZJg22D3Q.0TiIQ0uZYHHKLqrwggUXjA.3j3kT0b6oqJ4c062q5a6jg

Copy the complete result into the password-property value.
