open(fastaseq,"</Users/vishnushirishyamsaisundar/Desktop/SARS_COV_2/berlin/sequences_Berlin_2021.fasta");
open(FH,">N_content_berlin.csv");
print FH "Accession,Number_of_N\n";
while($line = <fastaseq>)
{
    chomp($string);
    if($line=~ m/^>/)
    {
   $line=~  m/>([A-Z0-9-]+)/;
   $acc = $1;
   $line=<fastaseq>;
    while($line=~ /([N]+)/g)
{
$string.=$1;


}
$count=length($string);
print FH "$acc,$count\n";
$string="";
}
}
