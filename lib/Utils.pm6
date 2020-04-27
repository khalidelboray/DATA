use HTTP::UserAgent;
use DOM::Tiny;
use JSON::Fast;

unit module Utils;

our $ua is export = HTTP::UserAgent.new;

sub fetch(Str $url, *%headers,Int :$maxtry = 3) is export {
    my $res;
    my $retry = 0;
    RETRY: try {
        CATCH {
            default {
                $retry++;
                goto RETRY if $retry != $maxtry;
            }
        }
        $res = $ua.get($url ,|%headers );
        return $res.content;
    }
}

sub scrape ( Callable $handler , Str $content ,Str $selector = '*') is export {
    my $dom = DOM::Tiny.parse: $content;
    $dom.find($selector).map( $handler );
}

sub lang-name ($code) is export {
    state %data = from-json slurp "../static/languages.json";
    return %data{$code}<name>.lc;
}