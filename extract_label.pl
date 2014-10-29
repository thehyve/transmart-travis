use JSON;
local $/;
my $json = <STDIN>;
$decoded_json = decode_json($json);
print STDOUT $decoded_json->{'head'}->{'label'};
