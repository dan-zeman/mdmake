#!/usr/bin/perl
# Multidimensional make. It generates a makefile and calls the system make.
# https://github.com/dan-zeman/mdmake
# https://wiki.ufal.ms.mff.cuni.cz/user:zeman:mdmake
# Copyright © 2009, 2023 Dan Zeman <zeman@ufal.mff.cuni.cz>
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
    # Remove the line break.
    $radek =~ s/\r?\n$//;
    # Remove comments.
    $radek =~ s/\#.*//;
    # Remove extra spaces at the end of the line (because of variable values etc.)
    $radek =~ s/\s+$//;
    # Does this line contain a variable assignment? It could be values of a dimension!
    if($radek =~ m/^([A-Z0-9_]+)\s*=\s*(.*)$/)
    {
        my $promenna = $1;
        my $hodnota = $2;
        # The function writes to global variable %promenne.
        zpracovat_promennou($promenna, $hodnota);
    }
    # Does this line define the list of dimensions?
    if($radek =~ m/^\.MDIMS:\s*(.*)/)
    {
        # The function writes to global variables %rozmery, @seznam_rozmeru, and $prozmer.
        zpracovat_mdims($1);
    }
    # Does this line define an "all" target?
    if($radek =~ m/^\.MDALL\s*:\s*(.*)/)
    {
        my @values = split(/\s+/, $1);
        push(@makefile_mdall, \@values);
        $_ = '';
    }
    # Does this line define a multidimensional input rule?
    if($radek =~ m/^\.MDIN\s*:(.*)/)
    {
        my $mdin = $1;
        # All values of all dimensions must be verified before the first multidimensional rule is processed.
        unless($kontrola_rozmeru_probehla)
        {
            $kontrola_rozmeru_probehla = 1;
            # The function writes to global variable %hodnota2rozmer.
            zkontrolovat_rozmery();
        }
        # Remove leading spaces, if any (trailing spaces should be already removed).
        $mdin =~ s/^\s+//;
        my ($invalues, $infile) = split(/\s*<\s*/, $mdin);
        $_ = zpracovat_mdin($invalues, $infile);
    }
    # Does a multidimensional rule start on this line?
    if($radek =~ m/^\.MDRULE/)
    {
        # All values of all dimensions must be verified before the first multidimensional rule is processed.
        unless($kontrola_rozmeru_probehla)
        {
            $kontrola_rozmeru_probehla = 1;
            # The function writes to global variable %hodnota2rozmer.
            zkontrolovat_rozmery();
        }
        # The line starting with .MDRULE only initiates reading of a MD rule.
        # We cannot process the rule until it is read completely.
        $cte_se_mdrule = 1;
        $_ = '';
    }
    elsif($cte_se_mdrule)
    {
        # A MD rule must end with an empty line.
        # (Warning! We are checking $_, not $radek, otherwise a comment within a rule would be considered as an empty line.)
        unless(m/^\s*$/)
        {
            # Add the current line to the MD rule.
            # This function does not write to global variables (but it reads them as everybody else).
            zpracovat_radek_mdrule($radek, \%mdrule);
            $_ = '';
        }
        # Process the MD rule we just read.
        else
        {
            # The function writes to global variable %rozmery_typu.
            zpracovat_mdrule(\%mdrule);
            # Save the rule for later processing (after all MD rules have been read).
            my %lokalni_kopie_mdr = %mdrule;
            push(@makefile, {'type' => 'mdrule', 'contents' => \%lokalni_kopie_mdr});
            # The MD rule is processed, clear the variables for the next rule.
            $cte_se_mdrule = 0;
            %mdrule = ();
        }
    }
    # If we did not realize above that the current line needs special processing, it stayed non-empty and we want to copy it.
    unless($_ eq '')
    {
        push(@makefile, {'type' => 'line', 'contents' => $_});
    }
}
close(MDMF);
# Go through the file just read.
# Lines that do not need special attention will be simply copied to the generated makefile.
# MD rules will be expanded.
open(GMKF, '>genmakefile.mak') or die("Cannot write genmakefile.mak: $!\n");
foreach my $prvek (@makefile)
{
    if($prvek->{type} eq 'line')
    {
        # Copied lines include the line break character.
        print GMKF ($prvek->{contents});
    }
    elsif($prvek->{type} eq 'mdrule')
    {
        my %mdrule = %{$prvek->{contents}};
        # From the perspective of a given rule, known dimensions fall into one of four groups:
        #   1. typ: The last dimension is the file type, it is thus fixed, but differently for each file in the rule.
        #   2. fix: The dimension has a fixed value in this rule, same for all files that know this dimension.
        #       2a: Some source files may have an exception, i.e., their own fixed value in a dimension, different
        #           from the value of this dimension at the other files.
        #   3. var: Dimensions with variable values, these are the dimensions in which the rule is expanded.
        #   4. unk: Dimensions that are unknown for the target and all the source files of this rule.
        # Figure out in which dimensions we will be moving.
        # $mdrule{rozmery} already enumerates the dimensions of the target file.
        # The source files may have some extra dimensions and may be lacking other dimensions.
        # %var will contain all dimensions whose value is not fixed for at least
        # one file in the rule. File hashes in the rule will be updated so that
        # each file knows its dimensions in this rule, as well as value of the
        # dimension if the value is fixed.
        my $var = pripravit_rozmery_v_pravidle(\%mdrule, \@seznam_rozmeru, $prozmer);
        my %var = %{$var};
        # Hash the current values of all dimensions so that we can easily use them in substitutions in commands.
        # (Only the fixed values now. The variable values will be added later in the loop.)
        my %hodnoty;
        foreach my $rozmer (@seznam_rozmeru)
        {
            if(exists($mdrule{fix}{$rozmer}))
            {
                $hodnoty{$rozmer} = $mdrule{fix}{$rozmer};
            }
        }
        # Hash %var contains the dimensions whose values alternate in this rule.
        # However, we want them in an array, in the required order.
        my @var = grep {exists($var{$_})} @seznam_rozmeru;
        print GMKF ("# Generating MD rule for the following dimensions: @var\n");
        # Expand all combinations of values in all participating dimensions.
        my @index = map {{'r' => $_, 'i' => 0, 'hi' => $#{$rozmery{$_}{hodnoty}}}} @var;
        # Hash individual index items so that current value in each dimension can be easily accessed.
        my %index;
        map {$index{$_->{r}} = $_} @index;
        my $konec = 0;
        while(!$konec)
        {
            # Rewrite current value indices with values of dimensions.
            # First update the global hash of values that will be later used for substitutions in commands.
            foreach my $rozmer (@seznam_rozmeru)
            {
                if(exists($index{$rozmer}))
                {
                    $hodnoty{$rozmer} = $rozmery{$rozmer}{hodnoty}[$index{$rozmer}{i}];
                }
            }
            # Do the same also separately for each file.
            foreach my $file (@{$mdrule{src}}, $mdrule{tgt})
            {
                foreach my $rozmer (@{$file->{rozmery}})
                {
                    # If the file has an exception and its own fixed value of the dimension, do not care whether the dimension is variable for other files.
                    if(exists($file->{fix}{$rozmer->{nazev}}))
                    {
                        $rozmer->{hodnota} = $file->{fix}{$rozmer->{nazev}};
                    }
                    # Insert the value only for variable dimensions.
                    elsif(exists($var{$rozmer->{nazev}}))
                    {
                        $rozmer->{hodnota} = $hodnoty{$rozmer->{nazev}};
                    }
                }
                # Construct the path to the file from the current values of dimensions.
                $file->{cesta} = join('', map {$_->{oddpred}.$_->{hodnota}.$_->{oddpo}} (@{$file->{rozmery}}));
            }
            # Remember all generated  target files and values that are used in their paths.
            # We will use them in the end to generate aggregate targets.
            ulozit_vygenerovany_cil(\@allfiles, $mdrule{tgt});
            # Construct the rule from the names of the files.
            my @zdrojsoubory = map {$_->{cesta}} @{$mdrule{src}};
            my $pravidlo = $mdrule{tgt}{cesta}.': '.join(' ', @zdrojsoubory);
            $pravidlo .= " $mdrule{dep}" if($mdrule{dep});
            print GMKF ("$pravidlo\n");
            # Print the commands of the rule.
            my $prikazy_po_substituci = provest_substituce_v_prikazech(\%mdrule, \%hodnoty, $pravidlo);
            print GMKF (join('', @{$prikazy_po_substituci}));
            # Increment the index.
            for(my $i = $#index; $i>=0; $i--)
            {
                $index[$i]{i}++;
                if($index[$i]{i} > $index[$i]{hi})
                {
                    $index[$i]{i} = 0;
                }
                else
                {
                    # $i-th index did not overflow, so the increment succeeded and we will not increment the higher indices.
                    last;
                }
                # If the highest index overflew, we have visited all combinations of indices and we can terminate the outer while as well.
                if($i==0)
                {
                    $konec = 1;
                }
            }
        }
    }
}
# Finally generate the required aggregate targets.
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
# In the standard workflow, we can now directly launch GNU make. But if we are debugging mdmake, it is better to stop here.
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
# SUBROUTINES
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
# Takes a MD rule and figures out the list of dimensions for which the rule
# shall be expanded (their values will alternate). Furthermore, prepares a list
# of dimensions for each file in the rule, and fills in the values of fixed
# dimensions.
#------------------------------------------------------------------------------
sub pripravit_rozmery_v_pravidle
{
    my $mdrule = shift; # hash ref
    my $seznam_rozmeru = shift; # array ref: all known dimensions
    my $prozmer = shift; # last dimension (file type)
    my @seznem_rozmeru = @{$seznam_rozmeru};
    # Find out in which dimensions we will be moving.
    # $mdrule{rozmery} already lists the dimensions of the target file.
    # However, the source files may have extra dimensions or may lack some
    # target dimensions.
    my %var;
    foreach my $s (@{$mdrule->{src}}, $mdrule->{tgt})
    {
        # Some source files may not have a defined list of dimensions because
        # they are input files of the whole system and are not built by a rule.
        # In that case assume that they have all known dimensions.
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
            # For dimensions whose values are fixed for this rule and file,
            # remember the fixed values.
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
        # Remember all dimensions of a file (source or target).
        $s->{rozmery} = \@rozmery;
    }
    # %var contains all dimensions that have variable (non-fixed) value for at
    # least one file in the rule.
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
