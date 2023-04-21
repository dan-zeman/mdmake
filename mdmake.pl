#!/usr/bin/perl
# Multidimenzionální make. Vygeneruje makefile a zavolá make.
# https://wiki.ufal.ms.mff.cuni.cz/user:zeman:rizeni-pokusu-pomoci-makefilu#mdmake
# Copyright © 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

sub usage
{
    print STDERR ("Usage: mdmake.pl\n");
    print STDERR ("       There must be a file called makefile.mdm in the current folder.\n");
    print STDERR ("       The file genmakefile.mak will be created or overwritten.\n");
}

open(MDMF, 'makefile.mdm') or die("Cannot read makefile.mdm: $!\n");
$iline = 0;
while(<MDMF>)
{
    $iline++;
    my $radek = $_;
    # Odstranit konec řádku.
    $radek =~ s/\r?\n$//;
    # Odstranit komentáře.
    $radek =~ s/\#.*//;
    # Odstranit přebytečné mezery na konci řádku (kvůli hodnotám proměnných apod.)
    $radek =~ s/\s+$//;
    # Obsahuje tento řádek přiřazení do proměnné? Mohly by to být hodnoty rozměru!
    if($radek =~ m/^([A-Z0-9_]+)\s*=\s*(.*)$/)
    {
        my $promenna = $1;
        my $hodnota = $2;
        # Zapisuje do globální proměnné %promenne.
        zpracovat_promennou($promenna, $hodnota);
    }
    # Je na tomto řádku definován seznam rozměrů?
    if($radek =~ m/^\.MDIMS:\s*(.*)/)
    {
        # Zapisuje do globálních proměnných %rozmery, @seznam_rozmeru a $prozmer.
        zpracovat_mdims($1);
    }
    # Obsahuje tento řádek požadavek na hromadný cíl?
    if($radek =~ m/^\.MDALL\s*:\s*(.*)/)
    {
        my @values = split(/\s+/, $1);
        push(@makefile_mdall, \@values);
        $_ = '';
    }
    # Obsahuje tento řádek vstupní vícerozměrné pravidlo?
    if($radek =~ m/^\.MDIN\s*:(.*)/)
    {
        my $mdin = $1;
        # Před prvním vícerozměrným pravidlem musí proběhnout kontrola všech hodnot všech rozměrů.
        unless($kontrola_rozmeru_probehla)
        {
            $kontrola_rozmeru_probehla = 1;
            # Zapisuje do globální proměnné %hodnota2rozmer.
            zkontrolovat_rozmery();
        }
        # Odstranit případné mezery na začátku (na konci už by měly být odstraněné).
        $mdin =~ s/^\s+//;
        my ($invalues, $infile) = split(/\s*<\s*/, $mdin);
        $_ = zpracovat_mdin($invalues, $infile);
    }
    # Začíná na tomto řádku vícerozměrné pravidlo?
    if($radek =~ m/^\.MDRULE/)
    {
        # Před prvním vícerozměrným pravidlem musí proběhnout kontrola všech hodnot všech rozměrů.
        unless($kontrola_rozmeru_probehla)
        {
            $kontrola_rozmeru_probehla = 1;
            # Zapisuje do globální proměnné %hodnota2rozmer.
            zkontrolovat_rozmery();
        }
        # Řádek začínající na .MDRULE akorát zapne čtení MD pravidla.
        # S jeho zpracováním musíme počkat, až bude přečteno celé.
        $cte_se_mdrule = 1;
        $_ = '';
    }
    elsif($cte_se_mdrule)
    {
        # MD pravidlo musí být ukončeno prázdným řádkem.
        # (Pozor! Kontrolujeme $_, nikoli $radek, jinak by se za prázdný řádek považoval i komentář uvnitř pravidla.)
        unless(m/^\s*$/)
        {
            # Přidat aktuální řádek k MD pravidlu.
            # Nezapisuje do globálních proměnných (ale čte je jako všichni).
            zpracovat_radek_mdrule($radek, \%mdrule);
            $_ = '';
        }
        # Zpracovat právě načtené MD pravidlo.
        else
        {
            # Zapisuje do globální proměnné %rozmery_typu.
            zpracovat_mdrule(\%mdrule);
            # Uložit pravidlo k pozdějšímu zpracování (až budou načtena všechna vícerozměrná pravidla).
            my %lokalni_kopie_mdr = %mdrule;
            push(@makefile, {'type' => 'mdrule', 'contents' => \%lokalni_kopie_mdr});
            # MD pravidlo je zpracováno, vynulovat proměnné pro příští pravidlo.
            $cte_se_mdrule = 0;
            %mdrule = ();
        }
    }
    # Pokud se výše nezjistilo, že aktuální řádek vyžaduje zvláštní zpracování, pak zůstal neprázdný a chceme ho opsat.
    unless($_ eq '')
    {
        push(@makefile, {'type' => 'line', 'contents' => $_});
    }
}
close(MDMF);
# Projít načtený soubor.
# Řádky, které pro nás nejsou podstatné, prostě okopírovat do generovaného makefilu.
# MD pravidla rozgenerovat.
open(GMKF, '>genmakefile.mak') or die("Cannot write genmakefile.mak: $!\n");
foreach my $prvek (@makefile)
{
    if($prvek->{type} eq 'line')
    {
        # Opisované řádky obsahují i znak konce řádku.
        print GMKF ($prvek->{contents});
    }
    elsif($prvek->{type} eq 'mdrule')
    {
        my %mdrule = %{$prvek->{contents}};
        # Rozměry, které známe, se z pohledu konkrétního pravidla dělí do čtyř skupin:
        #   1. typ: Poslední rozměr udává typ souboru, je tedy fixní, ale pro každý soubor pravidla jiný.
        #   2. fix: V tomto pravidle má zafixovanou hodnotu, pro všechny soubory (které tento rozměr znají) stejnou.
        #       2a: Některé zdrojové soubory mohou mít výjimku, tj. svou vlastní fixní hodnotu v nějakém rozměru, odlišnou
        #           od hodnoty tohoto rozměru u jiných souborů.
        #   3. var: Rozměry s proměnlivými hodnotami, podle nich se pravidlo rozgenerovává.
        #   4. unk: Rozměry, které ani cíl, ani žádný zdrojový soubor tohoto pravidla nezná.
        # Zjistit, ve kterých rozměrech se budeme pohybovat.
        # $mdrule{rozmery} už vyjmenovává rozměry cílového souboru.
        # Zdrojové soubory však mohou mít některé rozměry navíc, jiné jim zase můžou chybět.
        my $var = pripravit_rozmery_v_pravidle(\%mdrule);
        my %var = %{$var};
        # Nahashovat si aktuální hodnoty všech rozměrů pro snadné záměny v příkazech.
        # (Zatím jen fixní hodnoty, proměnlivé hodnoty doplníme později v cyklu.)
        my %hodnoty;
        foreach my $rozmer (@seznam_rozmeru)
        {
            if(exists($mdrule{fix}{$rozmer}))
            {
                $hodnoty{$rozmer} = $mdrule{fix}{$rozmer};
            }
        }
        # Hash %var obsahuje rozměry, jejichž hodnoty se v tomto pravidle mění.
        # My je ale chceme v poli, kde budou ve správném pořadí.
        my @var = grep {exists($var{$_})} @seznam_rozmeru;
        print GMKF ("# Generating MD rule for the following dimensions: @var\n");
        # Rozgenerovat všechny kombinace hodnot ve všech zúčastněných rozměrech.
        my @index = map {{'r'=>$_, 'i'=>0, 'hi'=>$#{$rozmery{$_}{hodnoty}}}} @var;
        # Nahashovat si jednotlivé položky indexu, abych snadno zjistil aktuální hodnotu v každém rozměru.
        my %index;
        map {$index{$_->{r}} = $_} @index;
        my $konec = 0;
        while(!$konec)
        {
            # Aktuální indexy hodnot přepsat na hodnoty rozměrů.
            # Nejdříve aktualizovat všeobecný hash hodnot, který bude později sloužit k substitucím v příkazech.
            foreach my $rozmer (@seznam_rozmeru)
            {
                if(exists($index{$rozmer}))
                {
                    $hodnoty{$rozmer} = $rozmery{$rozmer}{hodnoty}[$index{$rozmer}{i}];
                }
            }
            # Totéž ještě udělat zvlášť pro každý soubor.
            foreach my $file (@{$mdrule{src}}, $mdrule{tgt})
            {
                foreach my $rozmer (@{$file->{rozmery}})
                {
                    # Jestliže má soubor výjimku a svou vlastní fixní hodnotu rozměru, neohlížet se ani na to, zda je jinde rozměr proměnný.
                    if(exists($file->{fix}{$rozmer->{nazev}}))
                    {
                        $rozmer->{hodnota} = $file->{fix}{$rozmer->{nazev}};
                    }
                    # Hodnotu doplňovat pouze proměnlivým rozměrům.
                    elsif(exists($var{$rozmer->{nazev}}))
                    {
                        $rozmer->{hodnota} = $hodnoty{$rozmer->{nazev}};
                    }
                }
                # Zkonstruovat cestu k souboru z aktuálních hodnot rozměrů.
                $file->{cesta} = join('', map {$_->{oddpred}.$_->{hodnota}.$_->{oddpo}} (@{$file->{rozmery}}));
            }
            # Zapamatovat si všechny vygenerované cílové soubory a hodnoty, ze kterých jsou poskládané jejich cesty.
            # Na konci z nich budeme moci vygenerovat sdružené cíle.
            ulozit_vygenerovany_cil(\@allfiles, $mdrule{tgt});
            # Zkonstruovat pravidlo ze jmen souborů.
            my @zdrojsoubory = map {$_->{cesta}} @{$mdrule{src}};
            my $pravidlo = $mdrule{tgt}{cesta}.': '.join(' ', @zdrojsoubory);
            $pravidlo .= " $mdrule{dep}" if($mdrule{dep});
            print GMKF ("$pravidlo\n");
            # Vypsat příkazy pravidla.
            my $prikazy_po_substituci = provest_substituce_v_prikazech(\%mdrule, \%hodnoty, $pravidlo);
            print GMKF (join('', @{$prikazy_po_substituci}));
            # Zvýšit index.
            for(my $i = $#index; $i>=0; $i--)
            {
                $index[$i]{i}++;
                if($index[$i]{i} > $index[$i]{hi})
                {
                    $index[$i]{i} = 0;
                }
                else
                {
                    # $i-tý index nepřetekl, takže se zvýšení povedlo a vyšší indexy už nebudeme zvyšovat.
                    last;
                }
                # Jestliže přetekl i nejvyšší index, už jsme prošli všechny kombinace indexů a můžeme ukončit i vnější while.
                if($i==0)
                {
                    $konec = 1;
                }
            }
        }
    }
}
# Na závěr vygenerovat požadované hromadné cíle.
foreach my $values (@makefile_mdall)
{
    my @cile;
    foreach my $cil (@allfiles)
    {
        my $ok = 1;
        foreach my $hodnota (@{$values})
        {
            if(!$cil->{$hodnota})
            {
                $ok = 0;
                last;
            }
        }
        push(@cile, $cil->{':cesta:'}) if($ok);
    }
    if(scalar(@cile))
    {
        my $allcil = join('_', ('all', @{$values}));
        my $cleancil = join('_', ('clean', @{$values}));
        my $cile = join(' ', @cile);
        print GMKF (".PHONY: $allcil\n");
        print GMKF ("$allcil: $cile\n");
        print GMKF (".PHONY: $cleancil\n");
        print GMKF ("$cleancil:\n");
        print GMKF ("\trm -rf $cile\n");
    }
}
close(GMKF);
# V běžném provozu lze asi rovnou pustit GNU make. Ale při ladění mdmaku je lepší tady skončit.
if(0)
{
    print STDERR ("Now call 'make -f genmakefile.mak' to use the generated makefile.\n");
}
else
{
    # -j 3 (three parallel jobs allowed) should especially help with goals that are submitted to the cluster
    # It would be better if we did not have to limit the number of parallel cluster jobs at all.
    # Unfortunately, then also the local jobs could populate quickly and overload the local machine.
    my $command = "make -j 8 -f genmakefile.mak @ARGV";
    print STDERR ("$command\n");
    exec($command);
}



###############################################################################
# PODPROGRAMY
###############################################################################



#------------------------------------------------------------------------------
# Zpracuje jednoduché přiřazení do proměnné prostředí makefilu.
# Zapisuje do globální proměnné %promenne.
#------------------------------------------------------------------------------
sub zpracovat_promennou
{
    my $promenna = shift;
    my $hodnota = shift;
    # Opakované přiřazení do téže proměnné není zakázané, ale je neobvyklé a podezřelé.
    if(exists($promenne{$promenna}))
    {
        print STDERR ("Warning at makefile.mdm line $iline: Repeated definition of variable $promenna is ignored.\n");
        print STDERR ("  First definition was at line $promenne{$promenna}{iline}.\n");
    }
    else
    {
        my %zaznam =
        (
            'promenna' => $promenna,
            'hodnota'  => $hodnota,
            'iline'    => $iline
        );
        $promenne{$promenna} = \%zaznam;
    }
}



#------------------------------------------------------------------------------
# Zpracuje instrukci .MDIMS, která deklaruje známé rozměry.
# Zapisuje do globálních proměnných %rozmery, @seznam_rozmeru a $prozmer.
#------------------------------------------------------------------------------
sub zpracovat_mdims
{
    my $mdims = shift;
    # Tato definice by měla být v souboru právě jedna.
    if(scalar(keys(%rozmery)))
    {
        print STDERR ("Warning at makefile.mdm line $iline: Repeated definition of dimensions is ignored.\n");
    }
    else
    {
        # Deklarace seznamu rozměrů může být v souboru dříve než deklarace proměnných pro jednotlivé rozměry,
        # proto odložíme kontrolu hodnot rozměrů. Všechny rozměry však musejí být popsané dříve, než se objeví
        # první vícerozměrné pravidlo.
        my @mdims = split(/\s+/, $mdims);
        # Projít rozměry, najít a oddělit oddělovače.
        for(my $i = 0; $i <= $#mdims; $i++)
        {
            my $mdim = $mdims[$i];
            my %zaznam;
            if($mdim =~ s/^([-\.\/])//)
            {
                $zaznam{oddpred} = $1;
            }
            if($mdim =~ s/([-\.\/])$//)
            {
                $zaznam{oddpo} = $1;
            }
            # Zkontrolovat, že znaky, které zbyly, mohou tvořit název proměnné.
            if($mdim !~ m/^[A-Z0-9_]+$/)
            {
                print STDERR ("Name of variable must only contain characters [A-Z0-9_].\n");
                print STDERR ("  variable:         $mdim\n");
                print STDERR ("  delimiter before: $zaznam{oddpred}\n");
                print STDERR ("  delimiter after:  $zaznam{oddpo}\n");
                die("Error at makefile.mdm line $iline\n");
            }
            # Zkontrolovat, že tentýž rozměr není uveden více než jednou.
            if(exists($rozmery{$mdim}))
            {
                die("Error at makefile.mdm line $iline: The $mdim dimension used more than once.\n");
            }
            $zaznam{promenna} = $mdim;
            # Zapamatovat si u rozměru jeho pořadí v názvu souboru.
            $zaznam{poradi} = $i;
            # Uložit údaje o rozměru do globálního hashe.
            $rozmery{$mdim} = \%zaznam;
            # Zapamatovat si globální seznam rozměrů v daném pořadí.
            # Raději pojmenovat globální proměnnou jinak než @rozmery, které často používáme lokálně.
            push(@seznam_rozmeru, $mdim);
            # Zapamatovat si, který rozměr je poslední a udává stav práce.
            $prozmer = $mdim;
        }
    }
}



#------------------------------------------------------------------------------
# Před načtením prvního pravidla zkontroluje, že známe seznam rozměrů i hodnot.
# Zapisuje do globální proměnné %hodnota2rozmer.
#------------------------------------------------------------------------------
sub zkontrolovat_rozmery
{
    # Byl deklarován seznam rozměrů?
    my $ndim = scalar(keys(%rozmery));
    if($ndim==0)
    {
        die("Error at makefile.mdm line $iline: The list of dimensions must be defined before the first MD rule.\n");
    }
    # Projít všechny rozměry a zjistit, jestli k nim máme seznamy hodnot.
    # Protože pole @rozmery používáme na různých místech pro různé podmnožiny lokálně, uložit i globální kopii @seznam_rozmeru.
    my $nval = 0;
    my $ncomb = 1;
    foreach my $rozmer (@seznam_rozmeru)
    {
        if(!exists($promenne{$rozmer}))
        {
            die("Error at makefile.mdm line $iline: The values in dimension $rozmer must be defined before the first MD rule.\n");
        }
        else
        {
            # Hodnota rozměrové proměnné nesmí odkazovat na další proměnné.
            if($promenne{$rozmer}{hodnota} =~ m/\$/)
            {
                print STDERR ("Variables describing dimensions must be simple space-delimited lists of values.\n");
                print STDERR ("  References to other variables, macro calls and '$' occurrences in general are not permitted.\n");
                die("Error at makefile.mdm line $promenne{$rozmer}{iline}, dimension $rozmer.\n");
            }
            # Uložit hodnoty rozměru.
            else
            {
                my @hodnoty = split(/\s+/, $promenne{$rozmer}{hodnota});
                # Každý rozměr musí mít alespoň jednu hodnotu.
                my $nh = scalar(@hodnoty);
                if($nh==0)
                {
                    die("Error at makefile.mdm line $promenne{$rozmer}{iline}: Dimension $rozmer must have at least one value.\n");
                }
                $nval += $nh;
                $ncomb *= $nh;
                $rozmery{$rozmer}{hodnoty} = \@hodnoty;
                # Zapamatovat si u každé hodnoty, z jakého je rozměru, bude se nám to později hodit.
                foreach my $hodnota (@hodnoty)
                {
                    # Každá hodnota se smí objevit jen v jednom rozměru.
                    if(exists($hodnota2rozmer{$hodnota}))
                    {
                        print STDERR ("No value can appear in more than one dimension.\n");
                        my $rozmer0 = $hodnota2rozmer{$hodnota};
                        print STDERR ("  Value '$hodnota' appears in $rozmer0 at line $promenne{$rozmer0}{iline}.\n");
                        print STDERR ("  It also appears in $rozmer at line $promenne{$rozmer}{iline}.\n");
                        die("Error in makefile.mdm.\n");
                    }
                    $hodnota2rozmer{$hodnota} = $rozmer;
                }
            }
        }
    }
    # Vypsat na STDERR shrnutí rozměrů.
    print STDERR ("Total $ndim dimensions: @seznam_rozmeru\n");
    print STDERR ("Total $nval values and $ncomb value combinations\n");
    ###!!! Kontrola, že jména souborů nejsou kvůli chybějícím oddělovačům nejednoznačná, musí proběhnout pro každé pravidlo zvlášť,
    # protože v každém pravidle se používá jiná podmnožina rozměrů.
}



#------------------------------------------------------------------------------
# Zkontroluje pravidlo .MDIN.
# Zapisuje do globální proměnné %rozmery_typu.
# Vrací výstupní pravidlo, které se má zatím uložit a později vypsat.
#------------------------------------------------------------------------------
sub zpracovat_mdin
{
    my $invalues = shift;
    my $infile = shift;
    # Projít hodnoty, zjistit rozměry a nahashovat si je.
    my @invalues = split(/\s+/, $invalues);
    my $typ;
    my @rozmery_tohoto_typu;
    my %hodnota;
    foreach my $iv (@invalues)
    {
        if(!exists($hodnota2rozmer{$iv}))
        {
            die("Error at makefile.mdm line $iline: $iv is not a known value of any known dimension.\n");
        }
        my $rozmer = $hodnota2rozmer{$iv};
        # Žádný rozměr nesmí mít udanou více než jednu hodnotu.
        if(exists($hodnota{$rozmer}))
        {
            die("Error at makefile.mdm line $iline: More than one value of the $rozmer dimension.\n");
        }
        # Jestliže tento rozměr udává typ souboru, zapamatovat si typ.
        if($rozmer eq $prozmer)
        {
            $typ = $iv;
        }
        # Jestliže tento rozměr neudává typ, zapamatovat si ho mezi rozměry typu.
        else
        {
            push(@rozmery_tohoto_typu, $rozmer);
        }
        # Ke každému rozměru včetně typového si uložit aktuální hodnotu, abychom mohli sestavit cestu.
        $hodnota{$rozmer} = $iv;
    }
    # Zkontrolovat, že známe typ souboru.
    if($typ eq '')
    {
        die("Error at makefile.mdm line $iline: File type not specified (no known value of $prozmer found).\n");
    }
    # Zapamatovat si rozměry cílového typu souboru.
    # Pokud jsme se už s tímto typem setkali, zkontrolovat, že nyní pracujeme se stejným seznamem rozměrů.
    zkontrolovat_rozmery_typu($typ, @rozmery_tohoto_typu);
    # Získat seznam rozměrů cílového souboru ve správném pořadí.
    my @rozmery_souboru = grep {exists($hodnota{$_})} @seznam_rozmeru;
    # Sestavit cestu k cílovému souboru z hodnot v jednotlivých rozměrech.
    my $cesta = join('', map {$rozmery{$_}{oddpred}.$hodnota{$_}.$rozmery{$_}{oddpo}} (@rozmery_souboru));
    # Sestavit pravidlo pro zkopírování vstupního souboru.
    my $pravidlo = "$cesta: $infile\n\tcp \$< \$\@\n";
    return $pravidlo;
}



#------------------------------------------------------------------------------
# Zpracuje jeden řádek .MDRULE.
# Nezapisuje do globálních proměnných (ale čte je jako všichni).
#------------------------------------------------------------------------------
sub zpracovat_radek_mdrule
{
    my $radek = shift;
    my $mdrule = shift; # odkaz na hash
    # Přidat aktuální řádek k MD pravidlu.
    # Pokud řádek začíná na .md.rul, jde o popis (hodnoty posledního rozměru) cílových a zdrojových souborů.
    if($radek =~ m/^\.md\.rul:\s*(.*)/)
    {
        my ($tgt, $src) = split(/\s*<\s*/, $1);
        musi_byt_typ($tgt);
        # Pro každý zdrojový soubor vytvořit záznam, kde bude zatím jen typ souboru, ale později i jeho seznam rozměrů a hodnot.
        # Zdrojový soubor je v pravidle typicky reprezentován hodnotou posledního, typového rozměru.
        # Někdy ho ale mohou reprezentovat závorky s hodnotami několika rozměrů. Závorky nemohou být vnořené.
        my @src;
        my $src1 = $src;
        while($src1)
        {
            # Jestliže zbytek zdrojového řetězce začíná levou závorkou, zpracovat vše až do pravé závorky.
            if($src1 =~ s/^\((.*?)\)\s*//)
            {
                my $zavorky = $1;
                $zavorky =~ s/^\s+//;
                $zavorky =~ s/\s+$//;
                my @hodnoty = split(/\s+/, $zavorky);
                # Uložit si hodnoty pod názvy rozměrů.
                my $fix = nahashovat_hodnoty_podle_rozmeru(\@hodnoty);
                push(@src, {'typ' => $fix->{$prozmer}, 'fix' => $fix});
            }
            elsif($src1 =~ s/^(\S+)\s*//)
            {
                my $typ = $1;
                musi_byt_typ($typ);
                push(@src, {'typ' => $typ});
            }
            else
            {
                die("Error at makefile.mdm line $iline: cannot parse source string \"$src1\".\n");
            }
        }
        $mdrule->{tgt} = {'typ' => $tgt};
        $mdrule->{src} = \@src;
    }
    # Pokud řádek začíná na .md.dep, jde o fixní závislosti pravidla nezávislé na rozměrech.
    elsif($radek =~ m/^\.md\.dep:\s*(.*)/)
    {
        $mdrule->{dep} = $1;
    }
    # Pokud řádek začíná na .md.for, jde o seznam rozměrů cíle pravidla.
    elsif($radek =~ m/^\.md\.for:\s*(.*)/)
    {
        my @rozmery = split(/\s+/, $1);
        $mdrule->{rozmery} = \@rozmery;
    }
    # Pokud řádek začíná na .md.del, jde o seznam rozměrů, které se nemají použít pro cíl.
    # .md.del má přednost před .md.for, ale uplatní se spíše tam, kde .md.for není uvedeno, tj. defaultně by se braly všechny rozměry.
    elsif($radek =~ m/^\.md\.del:\s*(.*)/)
    {
        my @rozmery = split(/\s+/, $1);
        map {$mdrule->{del}{$_}++} @rozmery;
    }
    # Pokud řádek začíná na .md.fix, jde o seznam zafixovaných hodnot rozměrů.
    elsif($radek =~ m/^\.md\.fix:\s*(.*)/)
    {
        my @fix = split(/\s+/, $1);
        $mdrule->{fix} = \@fix;
        # Zkontrolovat, že jde o známé hodnoty rozměrů.
        foreach my $f (@fix)
        {
            musi_byt_hodnota($f);
        }
    }
    # Pokud řádek začíná na .md.fxd, je to jako .md.fix a .md.del dohromady.
    elsif($radek =~ m/^\.md\.fxd:\s*(.*)/)
    {
        my @fix = split(/\s+/, $1);
        $mdrule->{fxd} = \@fix;
    }
    # Pokud řádek začíná tabulátorem, jde o jeden z příkazů.
    elsif($radek =~ m/^\t/)
    {
        push(@{$mdrule->{prikazy}}, $radek);
    }
}



#------------------------------------------------------------------------------
# Zkontroluje načtené pravidlo .MDRULE a uloží ho k pozdějšímu rozgenerování,
# až budou načtena i všechna ostatní pravidla.
# Zapisuje do globální proměnné %rozmery_typu.
#------------------------------------------------------------------------------
sub zpracovat_mdrule
{
    my $mdrule = shift; # odkaz na hash
    # MD pravidlo musí definovat typ cíle.
    if(!exists($mdrule->{tgt}))
    {
        die("Error at makefile.mdm line $iline: The rule does not define the type of the target.\n");
    }
    # MD pravidlo nám také vymezuje rozměry, ve kterých se pohybuje cíl daného typu.
    # Nebyly-li stanoveny rozměry pro toto pravidlo, vzít všechny rozměry kromě posledního.
    if(!$mdrule->{rozmery} || scalar(@{$mdrule->{rozmery}})==0)
    {
        my @mdrozmery = @seznam_rozmeru;
        pop(@mdrozmery);
        die unless(scalar(@mdrozmery));
        $mdrule->{rozmery} = \@mdrozmery;
    }
    # Rozložit .md.fxd na .md.fix a .md.del.
    foreach my $fxd (@{$mdrule->{fxd}})
    {
        push(@{$mdrule->{fix}}, $fxd);
        $mdrule->{del}{$hodnota2rozmer{$fxd}}++;
    }
    delete($mdrule->{fxd});
    # Odstranit .md.del ze seznamu cílových rozměrů.
    for(my $i = 0; $i<=$#{$mdrule->{rozmery}}; $i++)
    {
        my $rozmer = $mdrule->{rozmery}[$i];
        if($mdrule->{del}{$rozmer})
        {
            splice(@{$mdrule->{rozmery}}, $i, 1);
            $i--;
        }
    }
    delete($mdrule->{del});
    # Zapamatovat si rozměry cílového typu souboru.
    # Pokud jsme se už s tímto typem setkali, zkontrolovat, že nyní pracujeme se stejným seznamem rozměrů.
    zkontrolovat_rozmery_typu($mdrule->{tgt}{typ}, @{$mdrule->{rozmery}});
    # Uložit si hodnoty pod názvy rozměrů (převést pole na hash).
    $mdrule->{fix} = nahashovat_hodnoty_podle_rozmeru($mdrule->{fix});
}



#------------------------------------------------------------------------------
# Pro daný typ cíle si zapamatuje seznam rozměrů, ve kterých se pohybuje.
# Pokud jsme se už s tímto typem setkali, zkontroluje, že nyní pracujeme se
# stejným seznamem rozměrů.
# Zapisuje do globální proměnné %rozmery_typu.
#------------------------------------------------------------------------------
sub zkontrolovat_rozmery_typu
{
    my $typ = shift;
    my @rozmery = @_;
    if(exists($rozmery_typu{$typ}))
    {
        my $old = join(' ', sort(@{$rozmery_typu{$typ}}));
        my $new = join(' ', sort(@rozmery));
        if($new ne $old)
        {
            print STDERR ("Error at makefile.mdm line $iline: mismatching list of dimensions for type $typ.\n");
            print STDERR ("  Old: $old\n");
            print STDERR ("  New: $new\n");
            die;
        }
    }
    else
    {
        $rozmery_typu{$typ} = \@rozmery;
    }
}



#------------------------------------------------------------------------------
# Pro MD pravidlo zjistí seznam rozměrů, pro které se má pravidlo rozgenerovat
# (jejich hodnoty se budou měnit). Současně ke každému zdrojovému i cílovému
# souboru pravidla připraví seznam jeho rozměrů a u fixních rozměrů rovnou
# vyplní i hodnoty.
#------------------------------------------------------------------------------
sub pripravit_rozmery_v_pravidle
{
    my $mdrule = shift; # odkaz na hash
    # Zjistit, ve kterých rozměrech se budeme pohybovat.
    # $mdrule{rozmery} už vyjmenovává rozměry cílového souboru.
    # Zdrojové soubory však mohou mít některé rozměry navíc, jiné jim zase můžou chybět.
    my %var;
    foreach my $s (@{$mdrule->{src}}, $mdrule->{tgt})
    {
        # Některé zdrojové soubory nemusejí mít definovaný seznam rozměrů,
        # jestliže nevznikají pravidlem, ale jsou to vstupní soubory celého systému.
        # V tom případě u nich předpokládáme všechny známé rozměry.
        my @nazvy_rozmeru_typu;
        if(exists($rozmery_typu{$s->{typ}}))
        {
            @nazvy_rozmeru_typu = (@{$rozmery_typu{$s->{typ}}}, $prozmer);
        }
        else
        {
            @nazvy_rozmeru_typu = @seznam_rozmeru;
        }
        my @rozmery;
        foreach my $rozmer (@nazvy_rozmeru_typu)
        {
            my %zaznam =
            (
                'nazev'   => $rozmer,
                'oddpred' => $rozmery{$rozmer}{oddpred},
                'oddpo'   => $rozmery{$rozmer}{oddpo}
            );
            # K rozměrům, jejichž hodnoty jsou v tomto pravidle fixní, si poznamenat i tyto hodnoty.
            if($rozmer eq $prozmer)
            {
                $zaznam{hodnota} = $s->{typ};
            }
            elsif(exists($mdrule->{fix}{$rozmer}))
            {
                $zaznam{hodnota} = $mdrule->{fix}{$rozmer};
            }
            elsif(exists($s->{fix}{$rozmer}))
            {
                $zaznam{hodnota} = $s->{fix}{$rozmer};
            }
            else
            {
                $var{$rozmer}++;
            }
            push(@rozmery, \%zaznam);
        }
        # Napsat si ke zdrojovému souboru jeho rozměry.
        $s->{rozmery} = \@rozmery;
    }
    return \%var;
}



#------------------------------------------------------------------------------
# Provede substituce v příkazech pravidla (aktuální hodnoty rozměrů, aktuální
# název n-tého zdrojového souboru) a vrátí seznam příkazů připravených
# k vypsání.
#------------------------------------------------------------------------------
sub provest_substituce_v_prikazech
{
    my $mdrule = shift; # odkaz na hash
    my $hodnoty = shift; # odkaz na hash s aktuálními hodnotami rozměrů
    my $pravidlo = shift; # aktuální tvar pravidla (využije se v chybovém hlášení)
    my @prikazy;
    # Vypsat příkazy pravidla.
    foreach my $prikaz (@{$mdrule->{prikazy}})
    {
        # Najít výskyty proměnných $(*ROZMER) a nahradit je aktuálními hodnotami v příslušném rozměru.
        my $prikaz1 = $prikaz;
        foreach my $rozmer (@seznam_rozmeru)
        {
            $prikaz1 =~ s/\$\(\*$rozmer\)/$hodnoty->{$rozmer}/g;
        }
        # Najít výskyty proměnných $(*N) a nahradit je jménem N-tého zdrojového souboru.
        for(my $i = 0; $i <= $#{$mdrule->{src}}; $i++)
        {
            my $i1 = $i+1;
            $prikaz1 =~ s/\$\(\*$i1\)/$mdrule->{src}[$i]{cesta}/g;
        }
        # V příkazu by neměla zbýt žádná proměnná typu $(*N). Zkontrolovat, že si autor nespletl počet zdrojových souborů.
        if($prikaz1 =~ m/(\$\(\*\d+\))/)
        {
            print STDERR ("$pravidlo\n");
            print STDERR ("\t$prikaz1\n");
            die("Error: Unknown source file $1 in the above command.\n");
        }
        push(@prikazy, "$prikaz1\n");
    }
    return \@prikazy;
}



#------------------------------------------------------------------------------
# Zapamatuje si vygenerované jméno cílového souboru a hodnoty rozměrů, ze
# ze kterých bylo vygenerováno. Seznam vygenerovaných jmen souborů nám na konci
# umožní vygenerovat hromadné cíle pro určité hodnoty určitých rozměrů.
#------------------------------------------------------------------------------
sub ulozit_vygenerovany_cil
{
    my $allfiles = shift; # odkaz na pole
    my $soubor = shift; # $mdrule{tgt}
    # Zapamatovat si všechny vygenerované cílové soubory a hodnoty, ze kterých jsou poskládané jejich cesty.
    # Na konci z nich budeme moci vygenerovat sdružené cíle.
    my %targetfile;
    foreach my $rozmer (@{$soubor->{rozmery}})
    {
        $targetfile{$rozmer->{hodnota}}++;
    }
    # Dvojtečka v klíči zajistí, že tohle nemohla být hodnota žádného rozměru (nelze ji použít v názvu souboru).
    $targetfile{':cesta:'} = $soubor->{cesta};
    push(@{$allfiles}, \%targetfile);
}



#------------------------------------------------------------------------------
# Zkontroluje, že řetězec je známá hodnota nějakého rozměru, v opačném případě
# hodí výjimku.
#------------------------------------------------------------------------------
sub musi_byt_hodnota
{
    my $retezec = shift;
    if(!exists($hodnota2rozmer{$retezec}))
    {
        die("Error at makefile.mdm line $iline: $retezec is not a known value of any known dimension.\n");
    }
}



#------------------------------------------------------------------------------
# Zkontroluje, že řetězec je známá hodnota posledního rozměru, který udává typ
# souboru. V opačném případě hodí výjimku.
#------------------------------------------------------------------------------
sub musi_byt_typ
{
    my $retezec = shift;
    musi_byt_hodnota($retezec);
    # Typem cíle musí být hodnota posledního rozměru.
    if($hodnota2rozmer{$retezec} ne $prozmer)
    {
        die("Error at makefile.mdm line $iline: $tgt is not a known file type (value of dimension $prozmer).\n");
    }
}



#------------------------------------------------------------------------------
# Projde seznam hodnot, zjistí, ke kterým rozměrům patří a nahashuje je podle
# rozměrů. Hodí výjimku, jestliže narazí na neznámou hodnotu nebo na více
# hodnot jednoho rozměru.
#------------------------------------------------------------------------------
sub nahashovat_hodnoty_podle_rozmeru
{
    my $hodnoty = shift; # odkaz na pole
    # Uložit si hodnoty pod názvy rozměrů.
    my %fix;
    foreach my $f (@{$hodnoty})
    {
        musi_byt_hodnota($f);
        my $rozmer = $hodnota2rozmer{$f};
        if(exists($fix{$rozmer}))
        {
            print STDERR ("Error at makefile.mdm line $iline: More than one fixed value of the $rozmer dimension.\n");
            print STDERR ("  Value 1: $fix{$rozmer}\n");
            print STDERR ("  Value 2: $f\n");
            die;
        }
        $fix{$rozmer} = $f;
    }
    return \%fix;
}
