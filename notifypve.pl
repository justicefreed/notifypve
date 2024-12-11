#!/usr/bin/perl
use strict;
use warnings;

BEGIN {
        eval {

                eval "require Getopt::Long::Descriptive" or die;
                Getopt::Long::Descriptive->import;
        };
        if ($@ && $@ =~ /Getopt::Long::Descriptive/) {
                print "You need to install module: Getopt::Long::Descriptive - attempting to install with 'apt install libgetopt-long-descriptive-perl'";
                system("apt", "install", "libgetopt-long-descriptive-perl");
                eval {

                        eval "require Getopt::Long::Descriptive" or die;
                        Getopt::Long::Descriptive->import;
                };
                if ($@ && $@ =~ /Getopt::Long::Descriptive/) {
                        print "Getopt::Long::Descriptive install unsuccessful. Try installing it yourself manually and run again";
                        exit;
                }
        }
        eval {

                eval "require JSON::Parse" or die;
                JSON::Parse->import;
        };
        if ($@ && $@ =~ /JSON::Parse/) {
                print "You need to install module: JSON::Parse - attempting to install with 'apt install libjson-parse-perl'";
                system("apt", "install", "libjson-parse-perl");
                eval {

                        eval "require JSON::Parse" or die;
                        JSON::Parse->import;
                };
                if ($@ && $@ =~ /JSON::Parse/) {
                        print "JSON::Parse install unsuccessful. Try installing it yourself manually and run again";
                        exit;
                }
        }
}

use PVE::SafeSyslog;
use PVE::Notify;
use PVE::INotify;
use Getopt::Long::Descriptive;
use JSON::Parse 'parse_json';

my ($opt, $usage) = describe_options(
        'notifypve %o <subject line with or without spaces>',
        [ 'message|m:s', "The message body for the notification. Defaults to empty string" ],
        [ 'file|f:s', "The file to insert into the message body for the notification." ],
        [ 'severity' => hidden => { one_of => [
                [ 'error|e'     => "Use severity level 'error' (highest). Default" ],
                [ 'warning|w'   => "Use severity level 'warning' (second-highest)" ],
                [ 'notice|n'    => "Use severity level 'notice' (second-lowest)" ],
                [ 'info|i'      => "Use severity level 'info' (lowest)" ]
        ] } ],
        [ 'json|j:s', "JSON string containing structured data to be used in a template. By default it won't populate anything unless you add the appropriate template fields in the template files." ],
        [ 'type|t=s', "metadata type value, untested for other options than 'system-mail'.  Might be useful for notification routing and filters", { default => "system-mail"} ],
        [ 'hostname|h=s', "metadata hostname to use instead of actual hostname. Might be useful for notification routing and filters" ],
        [ 'template=s', "Template to use. Defaults to the provided basic 'notif' but you can use system provided ones or make your own multiple custom ones.", { default => "notif" } ],
        [],
        [ 'showtemplates',  "print template reference and paths to editable template files"],
        [ 'help',       "print usage message and exit", { shortcircuit => 1 } ]
);
print($usage->text), exit if $opt->help();

my $template_dir = "/usr/share/pve-manager/templates/default/";
# ensure template files exist
my $notifbody = $template_dir . $opt->template() . "-body.txt.hbs";
my $notifbodyhtml = $template_dir . $opt->template() . "-body.html.hbs";
my $notifsubj = $template_dir . $opt->template() . "-subject.txt.hbs";
if ( ! -e $notifbody ) {
        open(my $file, ">", $notifbody) || die "Can't open file";
        print $file "{{message}}\n";
        close($file);
}
if ( ! -e $notifbodyhtml ) {
        open(my $file, ">", $notifbodyhtml) or die $!;
        print $file "<html>\n    <body>\n                {{message}}\n       </body>\n</html>\n";
        close($file);
}

if ( ! -e $notifsubj ) {
        open(my $file, ">", $notifsubj) or die $!;
        print $file "{{subject}}\n";
        close($file);
}
if ($opt->showtemplates()) {
        print "PVE Notifications use structured data inserted into templates in:\n";
        print $template_dir . "\n";
        print "The templates for the current template name are at these three paths:\n";
        print $notifsubj . "\n";
        print $notifbody . "\n";
        print $notifbodyhtml . "\n";
        print "See the rust implementation of the renderer for details:\n";
        print "https://git.proxmox.com/?p=proxmox.git;a=blob;f=proxmox-notify/src/renderer/mod.rs;h=e058ea2218b027018f0d13532404b205e3dc6366;hb=HEAD\n";
        exit;
}

my $subject = join( ' ', @ARGV );
print "WARNING:No subject provided" if ( ! $subject );
print "Sending notification with subject: " . $subject . "\n";

my $hostname = `hostname -f` || PVE::INotify::nodename();
chomp $hostname;
$hostname = $opt->hostname() if ($opt->hostname());
my $message = $opt->message();
if ($opt->file()) {
    $message = do {
        local $/ = undef;
        open my $fh, "<", $opt->file()
            or die "Could not open $opt->file(): $!";
        <$fh>;
    };
    chomp($message);
}
my $template_data = {
        "subject" => $subject,
        "message" => $opt->message()
};
if ($opt->json()) {
        my $json_data = JSON::Parse::parse_json($opt->json());
        $template_data = {%$template_data, %$json_data};
}
my $metadata_fields = {
        type => "system-mail",
        hostname => $hostname
};
my $severity = "error";
$severity = $opt->severity() if ($opt->severity());

PVE::Notify::notify($severity, $opt->template(), $template_data, $metadata_fields);
