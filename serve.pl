#!/usr/bin/perl
use v5.24;

use Encode::Locale;
use Mojolicious::Lite;
use Mojo::Util qw(encode getopt);
use Path::Tiny qw(cwd path);
use version;

# By default, serve from the current directory.
@{app->static->paths} = (cwd);

# Allow the user to set the static file path on the command line.
getopt \@ARGV, ['pass_through'], 'public=s' => \app->static->paths->[0];

# Remember the public files directory for later.
# We could have supported multiple public directories but it would be too confusing.
my $public = app->static->paths->[0];

# Kludge: Mojolicious tries to automatically determine Content-Type of static files
# and defaults to text/plain;charset=UTF-8. Override the default.
app->hook(after_static => sub {
	my $c = shift;
	$c->res->headers->content_type('application/octet-stream')
		if $c->res->headers->content_type =~ m{text/plain};
}) if version->parse($Mojolicious::VERSION) < version->parse('8.27');

# Static files are handled for us by Mojolicious thanks to the setup above,
# but we still need to produce listings.
get '/*dir' => { dir => undef } => sub {
	my $c = shift;
	my $arg = $c->stash("dir");

	# Translate the request to the path in the public directory
	my $path = path($public, defined $arg ? encode locale => $arg : ())->realpath;

	# Check if the client is trying to escape it
	return $c->render(text => 'Forbidden', status => 403)
		if path("..")->subsumes($path->relative($public));

	return $c->render(template => 'list', dir => $path) if $path->is_dir;

	return $c->reply->not_found;
};

app->start;

__DATA__

@@ list.html.ep
% use Mojo::Util 'decode';
%# Given a Path::Tiny object $dir, produce an HTML listing of files there.
<html>
<head><title><%= decode locale => $dir->basename %></title></head>
<body>
<ul>
%# Sort directories first, then alphabetically
% for my $c (sort { $b->is_dir <=> $a->is_dir or $a->basename cmp $b->basename } $dir->children) {
%  my $href = (decode locale => $c->basename) . ($c->is_dir ? '/' : '');
   <li><a href="<%=  $href %>"><%= $href %></a></li>
% }
</ul>
</body>
</html>
