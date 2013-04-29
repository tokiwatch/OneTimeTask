# $Id$

package OneTimeTask::Plugin;

use strict;
use warnings;

sub plugin {
    return MT->component('OneTimeTask');
}

sub _log {
    my ($msg) = @_; 
    return unless defined($msg);
    my $prefix = sprintf "%s:%s:%s: %s", caller();
    $msg = $prefix . $msg if $prefix;
    use MT::Log;
    my $log = MT::Log->new;
    $log->message($msg) ;
    $log->save or die $log->errstr;
    return;
}

sub one_time_task_pref {
    my $plugin = plugin();
    my ($blog_id) = @_;
    my %plugin_param;

    $plugin->load_config(\%plugin_param, 'blog:'.$blog_id);
    my $value = $plugin_param{one_time_task_pref};
    unless ($value) {
        $plugin->load_config(\%plugin_param, 'system');
        $value = $plugin_param{one_time_task_pref};
    }
    $value;
}


#----- Task
sub do_one_time_task {
    require MT::Blog;
    my $blogs = MT::Blog->load_iter or die "no blogs loading";
    CHECKBLOG: while (my $blog = $blogs->()) {
        my $blog_id = $blog->id;
        # check for enable this plugin on each blog.
        my $check_enable = get_config('one_time_task_enable', $blog_id);
        next CHECKBLOG unless $check_enable;
        # check for getting date as using cron
        my $check_cron_enable = get_config('one_time_task_cron_enable', $blog_id);
        next CHECKBLOG unless $check_cron_enable;

        require MT::Util;
        my $ts = MT::Util::epoch2ts( $blog, time() );
        my ($year, $month, $today, $local_hour, $local_min) = unpack ('A4A2A2A2A2', $ts);
        my $lastdate = get_config('one_time_task_lastdate', $blog_id);
        my $starttime = get_config('one_time_task_starttime', $blog_id);

        unless ($starttime){
            task();
        } else {
            if ($today != $lastdate) {
                die 'Format was worg: starttime' unless $starttime =~ m/\d\d:\d\d/;
                my ($starttime_hour, $starttime_min) = split(/:/, $starttime);

                my $local_total = $local_min + ($local_hour * 60);
                my $start_total = $starttime_min + ($starttime_hour * 60);

                if ($start_total <= $local_total) {
                    my $plugin = plugin();
                    $plugin->set_config_value('one_time_task_lastdate', $today, 'blog:'.$blog_id);
                    task();
                }
            }
        }
    }
    1;
}

sub task {
  _log("hoge");
  1;
}

1;
