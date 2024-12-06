# notifypve
Simple Utility to Send Notifications to Proxmox PVE Notification System

## What is it?
Proxmox recently released a notification system that allows for various options for filtering and routing notifications (such as sending a backup job error to your email address).  The system is supposed to support forwarding of system mail (sent to root@pam) into the notification system, but the implementation is still incomplete, and Proxmox does not expose any friendly API for directly using their notification system in any way.

This perl script hooks into the Proxmox notification system and allows you to send customized notifications.

## Basic Usage

```bash
# send a simple subject-only notification
notifypve This is my notification subject line

# send a notification with a subject and message body
notifypve "My Subject Line" -m "My message contents"
```

## Installation

You can paste the one-liner below to install the script into /usr/bin.

```bash
wget -O /usr/bin/notifypve https://raw.githubusercontent.com/justicefreed/notifypve/refs/heads/main/notifypve.pl && chmod +x /usr/bin/notifypve && /usr/bin/notifypve --help
```

## How it works

The proxmox notification system largely works by filling in pre-defined notification templates with the matching key-value pairs provided.  You can put your own data into their existing templates if you structure it correctly, but you can also define your own custom template files, which you can then populate however you'd like.

This script automatically creates a basic set of template files that it tells the notifier api to fill in with the provided data.

On initial run, the script will detect any missing import packages and will prompt to auto-install them (at least on debian).

The command syntax can be requested by passing the `--help` argument, for example:

```
root@proxmox:~# notifypve --help
notifypve [-ehijmntw] [long options...] <subject line with or without spaces>
        --message[=STR] (or -m)  The message body for the notification.
                                 Defaults to empty string
        --error (or -e)          Use severity level 'error' (highest). Default
        --warning (or -w)        Use severity level 'warning' (second-highest)
        --notice (or -n)         Use severity level 'notice' (second-lowest)
        --info (or -i)           Use severity level 'info' (lowest)
        --json[=STR] (or -j)     JSON string containing structured data to be
                                 used in a template. By default it won't
                                 populate anything unless you add the
                                 appropriate template fields in the template
                                 files.
        --type STR (or -t)       metadata type value, untested for other
                                 options than 'system-mail'.  Might be useful
                                 for notification routing and filters
        --hostname STR (or -h)   metadata hostname to use instead of actual
                                 hostname. Might be useful for notification
                                 routing and filters
        --template STR           Template to use. Defaults to the provided
                                 basic 'notif' but you can use system
                                 provided ones or make your own multiple
                                 custom ones.

        --showtemplates          print template reference and paths to
                                 editable template files
        --help                   print usage message and exit
```
