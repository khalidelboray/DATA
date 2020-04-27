use lib '../lib';
use Utils;
use DB::SQLite;

my $base = "https://hisnmuslim.com/";
my $s = DB::SQLite.new: :filename( 'hisnmuslim.db' );

my @langs = scrape {
                .attr("href").match(/\/(\w ** 2)\//)[0].Str
            } , fetch($base) , '.language-name';

my $db = $s.db;
$*OUT = $*OUT.open(:!buffer);

for @langs -> $lang {
    my @pages = scrape {
        %( [ :link(.attr('href')):title(.text.trim) ] )
    } , fetch($base ~ "/i/$lang/1"), '#chapter > ol > li > a';
    my $lang-name = lang-name($lang);
    $db.execute( "DROP TABLE IF EXISTS $lang-name;CREATE TABLE $lang-name (id INTEGER PRIMARY KEY, thikr text , at text );");
    put "Scraping Lang $lang-name  ";
    for @pages.kv -> $idx , %page {
        my $link = %page<link>;
        my $name = %page<title>;
        print "\t On Page [ $idx/132 ] \r";
        my @thikr = scrape {
            .all-text.trim
        } , fetch($link) , '.thikr';
        my $sth = $db.prepare( 'insert into \qq[$lang-name] (thikr,at) values (?,?)' );
        $db.begin;
        @thikr .map({ $sth.execute($_,$name)  });
        $db.commit;
    }
}
$db.finish;