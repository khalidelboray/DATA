use lib '../lib';
use Utils;
use DB::SQLite;

unit sub MAIN (
    Int :c(:$count) = 50,
    :d(:$diacritics) = 1 
);

my $s = DB::SQLite.new: :filename( 'hadith-all.db' );

my $base = "https://www.islambook.com/hadith/";





print "Getting Books Info ..";
my @books = scrape {

    %( [
                :name( .text.lc.trans: [ '-' , ' ' ] => [  '_' ] ):total( .at( 'span' ).text ):pages( ( .at( 'span' ).text / $count ).Int + 1 )
    ] )

} , fetch($base,cookie => "hadith_diacritics=$diacritics; hadith_size=$count; UserLanguage=en-US;") , 'ul[class="nav nav-pills nav-stacked"] > li a';

put " Done";

my $db = $s.db;
$*OUT = $*OUT.open(:!buffer);

for @books.kv -> $id , %info {
    my $name = %info<name>;
    $db.execute( "DROP TABLE IF EXISTS $name;CREATE TABLE $name (id INTEGER PRIMARY KEY, hadith text );");
    put "Scraping Book [ " ~ %info<name> ~" ] With Total [ " ~ %info<total> ~ " ] Hadith";

    for 1..%info<pages> -> $page {

       print "\t On Page [ $page ] of [ " ~  %info<pages> ~ " ]  \r";
       my @res = scrape {
           .all-text.trim
       } , fetch($base ~ "$id/$page",cookie => "hadith_diacritics=$diacritics; hadith_size=$count; UserLanguage=en-US;") , '.hadith';
       my $sth = $db.prepare( 'insert into \qq[$name] (hadith) values (?)' );
       $db.begin;
       @res.map({ $sth.execute($_)  });
       $db.commit;
      
    }
}   
$db.finish;