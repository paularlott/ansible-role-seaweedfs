package PVE::Storage::Custom::SeaweedFSPlugin;

use strict;
use warnings;
use IO::File;
use Net::IP;
use File::Path;

use PVE::Network;
use PVE::Tools qw(run_command);
use PVE::ProcFSTools;
use PVE::Storage::Plugin;
use PVE::JSONSchema qw(get_standard_option);

use base qw(PVE::Storage::Plugin);

sub api {
	my $apiver = PVE::Storage::APIVER;
	if ($apiver >= 9 and $apiver <= 10) {
			return $apiver;
	}

	return 10;
}

# Helper functions

sub seaweedfs_is_mounted {
  my ($filerpath, $mountpoint, $mountdata) = @_;

  $mountdata = PVE::ProcFSTools::parse_proc_mounts() if !$mountdata;

  return $mountpoint if grep {
		$_->[2] eq 'fuse.seaweedfs' &&
		$_->[0] =~ /^\S+:\Q$filerpath\E$/ &&
		$_->[1] eq $mountpoint
  } @$mountdata;
  return undef;
}

sub seaweedfs_mount {
  my ($filer, $filerpath, $disk, $collection, $cacheCapacityMB, $chunkSizeLimitMB, $replication, $mountpoint) = @_;

	# Create the option line
	my $options = "logtostderr=true,filer='$filer',filer.path=$filerpath";
	if ($disk) {
		$options .= ",disk=$disk";
	}
	if ($collection) {
		$options .= ",collection=$collection";
	}
	if ($cacheCapacityMB) {
		$options .= ",cacheCapacityMB=$cacheCapacityMB";
	}
	if ($chunkSizeLimitMB) {
		$options .= ",chunkSizeLimitMB=$chunkSizeLimitMB";
	}
	if ($replication) {
		$options .= ",replication=$replication";
	}

  my $cmd = ['/bin/mount', '-t', 'weed', 'fuse', '-o', $options, $mountpoint];
  run_command($cmd, errmsg => "mount error");
}

# Configuration

sub type {
  return 'seaweedfs';
}

sub plugindata {
  return {
		content => [ { images => 1, vztmpl => 1, iso => 1, backup => 1, snippets => 1, rootdir => 1 }, { images => 1 } ],
		format => [ { raw => 1, qcow2 => 1, vmdk => 1 } , 'raw' ],
  };
}

sub properties {
  return {
		filer => {
			description => "IP and Port of filer servers.",
			type => 'string',
		},
		filerpath => {
			description => "Filer path.",
			type => 'string',
		},
		disk => {
			description => "Disk type.",
			type => 'string',
			enum => ['', 'ssd', 'hdd'],
		},
		collection => {
			description => "Collection name.",
			type => 'string',
		},
		cacheCapacityMB => {
			description => "Cache capacity in MB.",
			type => 'integer',
		},
		chunkSizeLimitMB => {
			description => "Chunk size limit in MB.",
			type => 'integer',
		},
		replication => {
			description => "Replication factor.",
			type => 'string',
		},
  };
}

sub options {
  return {
		path => { fixed => 1 },
		filer => { fixed => 1 },
		filerpath => { fixed => 1 },
		disk => { optional => 1 },
		collection => { optional => 1 },
		cacheCapacityMB => { optional => 1 },
		chunkSizeLimitMB => { optional => 1 },
		replication => { optional => 1 },
		nodes => { optional => 1 },
		disable => { optional => 1 },
		maxfiles => { optional => 1 },
		'prune-backups' => { optional => 1 },
		content => { optional => 1 },
		format => { optional => 1 },
		mkdir => { optional => 1 },
		bwlimit => { optional => 1 },
		preallocation => { optional => 1 },
		shared => { optional => 1 },
  };
}

sub check_config {
	my ($class, $sectionId, $config, $create, $skipSchemaCheck) = @_;

	$config->{path} = "/mnt/pve/$sectionId" if $create && !$config->{path};

	return $class->SUPER::check_config($sectionId, $config, $create, $skipSchemaCheck);
}

# Storage implementation

sub status {
  my ($class, $storeid, $scfg, $cache) = @_;

  $cache->{mountdata} = PVE::ProcFSTools::parse_proc_mounts()
	if !$cache->{mountdata};

	my $path = $scfg->{path};
	my $filerpath = $scfg->{filerpath};

	return undef if !seaweedfs_is_mounted($filerpath, $path, $cache->{mountdata});

  return $class->SUPER::status($storeid, $scfg, $cache);
}

sub activate_storage {
  my ($class, $storeid, $scfg, $cache) = @_;

  $cache->{mountdata} = PVE::ProcFSTools::parse_proc_mounts()
	if !$cache->{mountdata};

	my $path = $scfg->{path};
	my $filer = $scfg->{filer};
	my $filerpath = $scfg->{filerpath};
	my $disk = $scfg->{disk};
	my $collection = $scfg->{collection};
	my $cacheCapacityMB = $scfg->{cacheCapacityMB};
	my $chunkSizeLimitMB = $scfg->{chunkSizeLimitMB};
	my $replication = $scfg->{replication};

  if (!seaweedfs_is_mounted($filerpath, $path, $cache->{mountdata})) {
		mkpath $path if !(defined($scfg->{mkdir}) && !$scfg->{mkdir});

		die "unable to activate storage '$storeid' - " .
			"directory '$path' does not exist\n" if ! -d $path;

		seaweedfs_mount($filer, $filerpath, $disk, $collection, $cacheCapacityMB, $chunkSizeLimitMB, $replication, $path);
  }

  $class->SUPER::activate_storage($storeid, $scfg, $cache);
}

sub deactivate_storage {
  my ($class, $storeid, $scfg, $cache) = @_;

  $cache->{mountdata} = PVE::ProcFSTools::parse_proc_mounts()
	if !$cache->{mountdata};

    my $path = $scfg->{path};
    my $filerpath = $scfg->{filerpath};

    if (seaweedfs_is_mounted($filerpath, $path, $cache->{mountdata})) {
		my $cmd = ['/bin/umount', $path];
		print "$path\n";
		run_command($cmd, errmsg => 'umount error');
  }
}

1;
