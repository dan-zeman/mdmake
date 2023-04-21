# Makefile for ICON 2009 NLP Tools Contest (parsing Indian languages)
# Adapted from Dan's makefile for CoNLL 2009 work cycle
# Copyright © 2007, 2009 Dan Zeman <zeman@ufal.mff.cuni.cz>

# Toto je zdrojový soubor pro mdmake.
# Z něj se vygeneruje makefile pro GNU make.

# Do not remove a file because it is considered intermediate.
.SECONDARY:
# Remove targets that had changed but their command ended with an error.
.DELETE_ON_ERROR:

# Where are the data sets?
PROGDIR = /home/zeman/projekty/parser
TOOLDIR = $(PARSINGROOT)/tools

# Které proměnné obsahují hodnoty v jednotlivých rozměrech, a jak se z nich složí jméno souboru?
# Povolené oddělovače jsou "/", "-" a ".".
# Oddělovač, který je přilepen k názvu rozměru, se vynechá, pokud soubor tento rozměr nepoužívá.
.MDIMS: ROUNDS/ LANGS/ DE TRAINTEST .STATES
ROUNDS = oldtags newtags
LANGS = hi bn te
DE = d e
TRAINTEST = train test
STATES = mconll rmconll csts stat dzg.csts astat dza.csts dz.conll mco malt.conll mst mst.conll malt.csts mst.csts dz.csts cmp.txt voted.conll dz.rconll malt.rconll mst.rconll voted.rconll dz.eval.txt malt.eval.txt mst.eval.txt voted.eval.txt voted.check.txt

.PHONY: all
all: all_d
.PHONY: final
final: all_e group3.zip

# This goal restricts morphological information in a CoNLL file so that the
# data is not too sparse while preserving information vital to parsing.
#
oldtags/hi/dtrain.rmconll: oldtags/hi/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/hi/dtest.rmconll: oldtags/hi/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/hi/etrain.rmconll: oldtags/hi/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/hi/etest.rmconll: oldtags/hi/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/bn/dtrain.rmconll: oldtags/bn/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/bn/dtest.rmconll: oldtags/bn/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/bn/etrain.rmconll: oldtags/bn/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/bn/etest.rmconll: oldtags/bn/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/te/dtrain.rmconll: oldtags/te/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/te/dtest.rmconll: oldtags/te/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/te/etrain.rmconll: oldtags/te/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
oldtags/te/etest.rmconll: oldtags/te/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/hi/dtrain.rmconll: newtags/hi/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/hi/dtest.rmconll: newtags/hi/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/hi/etrain.rmconll: newtags/hi/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/hi/etest.rmconll: newtags/hi/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/bn/dtrain.rmconll: newtags/bn/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/bn/dtest.rmconll: newtags/bn/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/bn/etrain.rmconll: newtags/bn/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/bn/etest.rmconll: newtags/bn/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/te/dtrain.rmconll: newtags/te/dtrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/te/dtest.rmconll: newtags/te/dtest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/te/etrain.rmconll: newtags/te/etrain.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@
newtags/te/etest.rmconll: newtags/te/etest.mconll conll_omezit_morfologii.pl
	conll_omezit_morfologii.pl < $< > $@

# This goal converts CoNLL files with morphology to CSTS. It discards parts of morphology and retains the rest.
#
oldtags/hi/dtrain.csts: oldtags/hi/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/hi/dtest.csts: oldtags/hi/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/hi/etrain.csts: oldtags/hi/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/hi/etest.csts: oldtags/hi/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/bn/dtrain.csts: oldtags/bn/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/bn/dtest.csts: oldtags/bn/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/bn/etrain.csts: oldtags/bn/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/bn/etest.csts: oldtags/bn/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/te/dtrain.csts: oldtags/te/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/te/dtest.csts: oldtags/te/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/te/etrain.csts: oldtags/te/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
oldtags/te/etest.csts: oldtags/te/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/hi/dtrain.csts: newtags/hi/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/hi/dtest.csts: newtags/hi/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/hi/etrain.csts: newtags/hi/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/hi/etest.csts: newtags/hi/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/bn/dtrain.csts: newtags/bn/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/bn/dtest.csts: newtags/bn/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/bn/etrain.csts: newtags/bn/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/bn/etest.csts: newtags/bn/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/te/dtrain.csts: newtags/te/dtrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/te/dtest.csts: newtags/te/dtest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/te/etrain.csts: newtags/te/etrain.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@
newtags/te/etest.csts: newtags/te/etest.mconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< | \
	  perl -pe 'if(m/<t>(.*?)<r>/) { my $$t = $$1; $$t =~ s/\t/|/g; $$t =~ s/\|g-.*?\|n-.*?\|p-[^|]*//; $$t =~ s/\|t-.*//; s/<t>.*?<r>/<t>$$t<r>/; }' > $@

# This goal trains the DZ parser.
#
oldtags/hi/d.stat: oldtags/hi/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
oldtags/hi/e.stat: oldtags/hi/etrain.csts
	$(PROGDIR)/train.pl < $< > $@
oldtags/bn/d.stat: oldtags/bn/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
oldtags/bn/e.stat: oldtags/bn/etrain.csts
	$(PROGDIR)/train.pl < $< > $@
oldtags/te/d.stat: oldtags/te/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
oldtags/te/e.stat: oldtags/te/etrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/hi/d.stat: newtags/hi/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/hi/e.stat: newtags/hi/etrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/bn/d.stat: newtags/bn/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/bn/e.stat: newtags/bn/etrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/te/d.stat: newtags/te/dtrain.csts
	$(PROGDIR)/train.pl < $< > $@
newtags/te/e.stat: newtags/te/etrain.csts
	$(PROGDIR)/train.pl < $< > $@

# This goal parses a CSTS file.
#
oldtags/hi/dtest.dzg.csts: oldtags/hi/dtest.csts oldtags/hi/d.stat
	$(PROGDIR)/parse.pl -m oldtags/hi/d.stat < $< > $@
oldtags/hi/etest.dzg.csts: oldtags/hi/etest.csts oldtags/hi/e.stat
	$(PROGDIR)/parse.pl -m oldtags/hi/e.stat < $< > $@
oldtags/bn/dtest.dzg.csts: oldtags/bn/dtest.csts oldtags/bn/d.stat
	$(PROGDIR)/parse.pl -m oldtags/bn/d.stat < $< > $@
oldtags/bn/etest.dzg.csts: oldtags/bn/etest.csts oldtags/bn/e.stat
	$(PROGDIR)/parse.pl -m oldtags/bn/e.stat < $< > $@
oldtags/te/dtest.dzg.csts: oldtags/te/dtest.csts oldtags/te/d.stat
	$(PROGDIR)/parse.pl -m oldtags/te/d.stat < $< > $@
oldtags/te/etest.dzg.csts: oldtags/te/etest.csts oldtags/te/e.stat
	$(PROGDIR)/parse.pl -m oldtags/te/e.stat < $< > $@
newtags/hi/dtest.dzg.csts: newtags/hi/dtest.csts newtags/hi/d.stat
	$(PROGDIR)/parse.pl -m newtags/hi/d.stat < $< > $@
newtags/hi/etest.dzg.csts: newtags/hi/etest.csts newtags/hi/e.stat
	$(PROGDIR)/parse.pl -m newtags/hi/e.stat < $< > $@
newtags/bn/dtest.dzg.csts: newtags/bn/dtest.csts newtags/bn/d.stat
	$(PROGDIR)/parse.pl -m newtags/bn/d.stat < $< > $@
newtags/bn/etest.dzg.csts: newtags/bn/etest.csts newtags/bn/e.stat
	$(PROGDIR)/parse.pl -m newtags/bn/e.stat < $< > $@
newtags/te/dtest.dzg.csts: newtags/te/dtest.csts newtags/te/d.stat
	$(PROGDIR)/parse.pl -m newtags/te/d.stat < $< > $@
newtags/te/etest.dzg.csts: newtags/te/etest.csts newtags/te/e.stat
	$(PROGDIR)/parse.pl -m newtags/te/e.stat < $< > $@

# This goal trains the syntactic-tag assigner.
#
oldtags/hi/d.astat: oldtags/hi/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
oldtags/hi/e.astat: oldtags/hi/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
oldtags/bn/d.astat: oldtags/bn/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
oldtags/bn/e.astat: oldtags/bn/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
oldtags/te/d.astat: oldtags/te/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
oldtags/te/e.astat: oldtags/te/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/hi/d.astat: newtags/hi/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/hi/e.astat: newtags/hi/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/bn/d.astat: newtags/bn/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/bn/e.astat: newtags/bn/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/te/d.astat: newtags/te/dtrain.csts
	$(PROGDIR)/atrain.pl < $< > $@
newtags/te/e.astat: newtags/te/etrain.csts
	$(PROGDIR)/atrain.pl < $< > $@

# This goal assigns syntactic tags to dependencies.
#
oldtags/hi/dtest.dza.csts: oldtags/hi/dtest.dzg.csts oldtags/hi/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/hi/d.astat -z mdgdz < $< > $@
oldtags/hi/etest.dza.csts: oldtags/hi/etest.dzg.csts oldtags/hi/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/hi/e.astat -z mdgdz < $< > $@
oldtags/bn/dtest.dza.csts: oldtags/bn/dtest.dzg.csts oldtags/bn/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/bn/d.astat -z mdgdz < $< > $@
oldtags/bn/etest.dza.csts: oldtags/bn/etest.dzg.csts oldtags/bn/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/bn/e.astat -z mdgdz < $< > $@
oldtags/te/dtest.dza.csts: oldtags/te/dtest.dzg.csts oldtags/te/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/te/d.astat -z mdgdz < $< > $@
oldtags/te/etest.dza.csts: oldtags/te/etest.dzg.csts oldtags/te/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m oldtags/te/e.astat -z mdgdz < $< > $@
newtags/hi/dtest.dza.csts: newtags/hi/dtest.dzg.csts newtags/hi/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/hi/d.astat -z mdgdz < $< > $@
newtags/hi/etest.dza.csts: newtags/hi/etest.dzg.csts newtags/hi/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/hi/e.astat -z mdgdz < $< > $@
newtags/bn/dtest.dza.csts: newtags/bn/dtest.dzg.csts newtags/bn/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/bn/d.astat -z mdgdz < $< > $@
newtags/bn/etest.dza.csts: newtags/bn/etest.dzg.csts newtags/bn/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/bn/e.astat -z mdgdz < $< > $@
newtags/te/dtest.dza.csts: newtags/te/dtest.dzg.csts newtags/te/d.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/te/d.astat -z mdgdz < $< > $@
newtags/te/etest.dza.csts: newtags/te/etest.dzg.csts newtags/te/e.astat $(PROGDIR)/aclass.pl
	$(PROGDIR)/aclass.pl -m newtags/te/e.astat -z mdgdz < $< > $@

# This goal converts parsed CSTS to parsed CoNLL.
# It also copies the CoNLL fields that are not available in CSTS
# (or should not have been modified by the parser) from the original CoNLL input.
#
oldtags/hi/dtest.dz.conll: oldtags/hi/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
oldtags/hi/etest.dz.conll: oldtags/hi/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
oldtags/bn/dtest.dz.conll: oldtags/bn/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
oldtags/bn/etest.dz.conll: oldtags/bn/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
oldtags/te/dtest.dz.conll: oldtags/te/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
oldtags/te/etest.dz.conll: oldtags/te/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/hi/dtest.dz.conll: newtags/hi/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/hi/etest.dz.conll: newtags/hi/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/bn/dtest.dz.conll: newtags/bn/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/bn/etest.dz.conll: newtags/bn/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/te/dtest.dz.conll: newtags/te/dtest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@
newtags/te/etest.dz.conll: newtags/te/etest.dza.csts $(TOOLDIR)/csts2conll.pl
	$(TOOLDIR)/csts2conll.pl -y 2006 < $< > $@

# This goal trains the Malt parser.
# Hindi: use POSTAG+case+postposition
# Bangla, Telugu: use CPOSTAG only
#
oldtags/hi/d.mco: oldtags/hi/dtrain.rmconll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stacklazy
oldtags/hi/e.mco: oldtags/hi/etrain.rmconll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stacklazy
newtags/hi/d.mco: newtags/hi/dtrain.rmconll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stacklazy
newtags/hi/e.mco: newtags/hi/etrain.rmconll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stacklazy

oldtags/bn/d.mco: oldtags/bn/dtrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a covproj
oldtags/bn/e.mco: oldtags/bn/etrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a covproj
newtags/bn/d.mco: newtags/bn/dtrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a covproj
newtags/bn/e.mco: newtags/bn/etrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a covproj

oldtags/te/d.mco: oldtags/te/dtrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stackeager
oldtags/te/e.mco: oldtags/te/etrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stackeager
newtags/te/d.mco: newtags/te/dtrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stackeager
newtags/te/e.mco: newtags/te/etrain.conll trainmalt.pl
	trainmalt.pl -c $@ -i $< -a stackeager

# This goal parses a CoNLL file using the Malt parser.
#
oldtags/hi/dtest.malt.conll: oldtags/hi/dtest.rmconll oldtags/hi/d.mco malt.pl
	malt.pl -c oldtags/hi/d.mco -i $< -o $@ -a stacklazy
oldtags/hi/etest.malt.conll: oldtags/hi/etest.rmconll oldtags/hi/e.mco malt.pl
	malt.pl -c oldtags/hi/e.mco -i $< -o $@ -a stacklazy
newtags/hi/dtest.malt.conll: newtags/hi/dtest.rmconll newtags/hi/d.mco malt.pl
	malt.pl -c newtags/hi/d.mco -i $< -o $@ -a stacklazy
newtags/hi/etest.malt.conll: newtags/hi/etest.rmconll newtags/hi/e.mco malt.pl
	malt.pl -c newtags/hi/e.mco -i $< -o $@ -a stacklazy

oldtags/bn/dtest.malt.conll: oldtags/bn/dtest.conll oldtags/bn/d.mco malt.pl
	malt.pl -c oldtags/bn/d.mco -i $< -o $@ -a covproj
oldtags/bn/etest.malt.conll: oldtags/bn/etest.conll oldtags/bn/e.mco malt.pl
	malt.pl -c oldtags/bn/e.mco -i $< -o $@ -a covproj
newtags/bn/dtest.malt.conll: newtags/bn/dtest.conll newtags/bn/d.mco malt.pl
	malt.pl -c newtags/bn/d.mco -i $< -o $@ -a covproj
newtags/bn/etest.malt.conll: newtags/bn/etest.conll newtags/bn/e.mco malt.pl
	malt.pl -c newtags/bn/e.mco -i $< -o $@ -a covproj

oldtags/te/dtest.malt.conll: oldtags/te/dtest.conll oldtags/te/d.mco malt.pl
	malt.pl -c oldtags/te/d.mco -i $< -o $@ -a stackeager
oldtags/te/etest.malt.conll: oldtags/te/etest.conll oldtags/te/e.mco malt.pl
	malt.pl -c oldtags/te/e.mco -i $< -o $@ -a stackeager
newtags/te/dtest.malt.conll: newtags/te/dtest.conll newtags/te/d.mco malt.pl
	malt.pl -c newtags/te/d.mco -i $< -o $@ -a stackeager
newtags/te/etest.malt.conll: newtags/te/etest.conll newtags/te/e.mco malt.pl
	malt.pl -c newtags/te/e.mco -i $< -o $@ -a stackeager

# This goal trains the MST parser.
# Warning: even on the small Indian data sets, and on the cluster, training takes 4 gigs and 1-2 hours.
# Warning: projective training is default. Use option decode-type:non-proj.
# Warning: this goal submits a job to the cluster and does not wait for it to terminate.
#          It means that make will proceed to another goal without having the trained model ready.
#
oldtags/hi/d.mst: oldtags/hi/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
oldtags/hi/e.mst: oldtags/hi/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
oldtags/bn/d.mst: oldtags/bn/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
oldtags/bn/e.mst: oldtags/bn/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
oldtags/te/d.mst: oldtags/te/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
oldtags/te/e.mst: oldtags/te/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/hi/d.mst: newtags/hi/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/hi/e.mst: newtags/hi/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/bn/d.mst: newtags/bn/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/bn/e.mst: newtags/bn/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/te/d.mst: newtags/te/dtrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1
newtags/te/e.mst: newtags/te/etrain.rmconll
	trainmst.pl train-file:$< model-name:$@
	exit 1

# This goal parses a CoNLL file using the MST parser.
# Warning: -Xmx1800m (suggested in documentation) is not enough. Go to cluster!
# Warning: projective parsing is default. Use option decode-type:non-proj.
# Warning: MST parser wants input with heads as numbers (not "_"), even though it will overwrite them.
#
oldtags/hi/dtest.mst.conll: oldtags/hi/dtest.rmconll oldtags/hi/d.mst
	mst.pl model-name:oldtags/hi/d.mst test-file:$< output-file:$@
	exit 1
oldtags/hi/etest.mst.conll: oldtags/hi/etest.rmconll oldtags/hi/e.mst
	mst.pl model-name:oldtags/hi/e.mst test-file:$< output-file:$@
	exit 1
oldtags/bn/dtest.mst.conll: oldtags/bn/dtest.rmconll oldtags/bn/d.mst
	mst.pl model-name:oldtags/bn/d.mst test-file:$< output-file:$@
	exit 1
oldtags/bn/etest.mst.conll: oldtags/bn/etest.rmconll oldtags/bn/e.mst
	mst.pl model-name:oldtags/bn/e.mst test-file:$< output-file:$@
	exit 1
oldtags/te/dtest.mst.conll: oldtags/te/dtest.rmconll oldtags/te/d.mst
	mst.pl model-name:oldtags/te/d.mst test-file:$< output-file:$@
	exit 1
oldtags/te/etest.mst.conll: oldtags/te/etest.rmconll oldtags/te/e.mst
	mst.pl model-name:oldtags/te/e.mst test-file:$< output-file:$@
	exit 1
newtags/hi/dtest.mst.conll: newtags/hi/dtest.rmconll newtags/hi/d.mst
	mst.pl model-name:newtags/hi/d.mst test-file:$< output-file:$@
	exit 1
newtags/hi/etest.mst.conll: newtags/hi/etest.rmconll newtags/hi/e.mst
	mst.pl model-name:newtags/hi/e.mst test-file:$< output-file:$@
	exit 1
newtags/bn/dtest.mst.conll: newtags/bn/dtest.rmconll newtags/bn/d.mst
	mst.pl model-name:newtags/bn/d.mst test-file:$< output-file:$@
	exit 1
newtags/bn/etest.mst.conll: newtags/bn/etest.rmconll newtags/bn/e.mst
	mst.pl model-name:newtags/bn/e.mst test-file:$< output-file:$@
	exit 1
newtags/te/dtest.mst.conll: newtags/te/dtest.rmconll newtags/te/d.mst
	mst.pl model-name:newtags/te/d.mst test-file:$< output-file:$@
	exit 1
newtags/te/etest.mst.conll: newtags/te/etest.rmconll newtags/te/e.mst
	mst.pl model-name:newtags/te/e.mst test-file:$< output-file:$@
	exit 1

# This goal compares the outputs of the three parsers (Malt, MST and DZ).
# The result is oracle accuracy, i.e. upper limit to the accuracy achievable by parser combination.
#
oldtags/hi/dtest.malt.csts: oldtags/hi/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/hi/etest.malt.csts: oldtags/hi/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/bn/dtest.malt.csts: oldtags/bn/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/bn/etest.malt.csts: oldtags/bn/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/te/dtest.malt.csts: oldtags/te/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
oldtags/te/etest.malt.csts: oldtags/te/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/hi/dtest.malt.csts: newtags/hi/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/hi/etest.malt.csts: newtags/hi/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/bn/dtest.malt.csts: newtags/bn/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/bn/etest.malt.csts: newtags/bn/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/te/dtest.malt.csts: newtags/te/dtest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/te/etest.malt.csts: newtags/te/etest.malt.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@

oldtags/hi/dtest.mst.csts: oldtags/hi/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/hi/etest.mst.csts: oldtags/hi/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/bn/dtest.mst.csts: oldtags/bn/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/bn/etest.mst.csts: oldtags/bn/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/te/dtest.mst.csts: oldtags/te/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
oldtags/te/etest.mst.csts: oldtags/te/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/hi/dtest.mst.csts: newtags/hi/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/hi/etest.mst.csts: newtags/hi/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/bn/dtest.mst.csts: newtags/bn/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/bn/etest.mst.csts: newtags/bn/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/te/dtest.mst.csts: newtags/te/dtest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/te/etest.mst.csts: newtags/te/etest.mst.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@

oldtags/hi/dtest.dz.csts: oldtags/hi/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/hi/etest.dz.csts: oldtags/hi/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
oldtags/bn/dtest.dz.csts: oldtags/bn/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/bn/etest.dz.csts: oldtags/bn/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
oldtags/te/dtest.dz.csts: oldtags/te/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
oldtags/te/etest.dz.csts: oldtags/te/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/hi/dtest.dz.csts: newtags/hi/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/hi/etest.dz.csts: newtags/hi/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l hi < $< > $@
newtags/bn/dtest.dz.csts: newtags/bn/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/bn/etest.dz.csts: newtags/bn/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l bn < $< > $@
newtags/te/dtest.dz.csts: newtags/te/dtest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@
newtags/te/etest.dz.csts: newtags/te/etest.dz.rconll
	$(TOOLDIR)/conll2csts.pl -y 2006 -l te < $< > $@

# Note: The script performing the comparison is not listed as dependency because we want to use $^.
oldtags/hi/dtest.cmp.txt: oldtags/hi/dtest.csts oldtags/hi/dtest.malt.csts oldtags/hi/dtest.mst.csts oldtags/hi/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
oldtags/hi/etest.cmp.txt: oldtags/hi/etest.csts oldtags/hi/etest.malt.csts oldtags/hi/etest.mst.csts oldtags/hi/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
oldtags/bn/dtest.cmp.txt: oldtags/bn/dtest.csts oldtags/bn/dtest.malt.csts oldtags/bn/dtest.mst.csts oldtags/bn/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
oldtags/bn/etest.cmp.txt: oldtags/bn/etest.csts oldtags/bn/etest.malt.csts oldtags/bn/etest.mst.csts oldtags/bn/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
oldtags/te/dtest.cmp.txt: oldtags/te/dtest.csts oldtags/te/dtest.malt.csts oldtags/te/dtest.mst.csts oldtags/te/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
oldtags/te/etest.cmp.txt: oldtags/te/etest.csts oldtags/te/etest.malt.csts oldtags/te/etest.mst.csts oldtags/te/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/hi/dtest.cmp.txt: newtags/hi/dtest.csts newtags/hi/dtest.malt.csts newtags/hi/dtest.mst.csts newtags/hi/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/hi/etest.cmp.txt: newtags/hi/etest.csts newtags/hi/etest.malt.csts newtags/hi/etest.mst.csts newtags/hi/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/bn/dtest.cmp.txt: newtags/bn/dtest.csts newtags/bn/dtest.malt.csts newtags/bn/dtest.mst.csts newtags/bn/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/bn/etest.cmp.txt: newtags/bn/etest.csts newtags/bn/etest.malt.csts newtags/bn/etest.mst.csts newtags/bn/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/te/dtest.cmp.txt: newtags/te/dtest.csts newtags/te/dtest.malt.csts newtags/te/dtest.mst.csts newtags/te/dtest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@
newtags/te/etest.cmp.txt: newtags/te/etest.csts newtags/te/etest.malt.csts newtags/te/etest.mst.csts newtags/te/etest.dz.csts
	$(TOOLDIR)/porovnat.pl $^ > $@

# The following goals use the outputs of the three parsers (Malt, MST and DZ) to vote about the ultimate outcome.
#
oldtags/hi/dtest.voted.conll: oldtags/hi/dtest.malt.rconll oldtags/hi/dtest.mst.rconll oldtags/hi/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8760 oldtags/hi/dtest.malt.rconll 8616 oldtags/hi/dtest.mst.rconll 7512 oldtags/hi/dtest.dz.rconll > $@
oldtags/hi/etest.voted.conll: oldtags/hi/etest.malt.rconll oldtags/hi/etest.mst.rconll oldtags/hi/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8760 oldtags/hi/etest.malt.rconll 8616 oldtags/hi/etest.mst.rconll 7512 oldtags/hi/etest.dz.rconll > $@
newtags/hi/dtest.voted.conll: newtags/hi/dtest.malt.rconll newtags/hi/dtest.mst.rconll newtags/hi/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8760 newtags/hi/dtest.malt.rconll 8616 newtags/hi/dtest.mst.rconll 7512 newtags/hi/dtest.dz.rconll > $@
newtags/hi/etest.voted.conll: newtags/hi/etest.malt.rconll newtags/hi/etest.mst.rconll newtags/hi/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8760 newtags/hi/etest.malt.rconll 8616 newtags/hi/etest.mst.rconll 7512 newtags/hi/etest.dz.rconll > $@

oldtags/bn/dtest.voted.conll: oldtags/bn/dtest.malt.rconll oldtags/bn/dtest.mst.rconll oldtags/bn/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8557 oldtags/bn/dtest.malt.rconll 8570 oldtags/bn/dtest.mst.rconll 5438 oldtags/bn/dtest.dz.rconll > $@
oldtags/bn/etest.voted.conll: oldtags/bn/etest.malt.rconll oldtags/bn/etest.mst.rconll oldtags/bn/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8557 oldtags/bn/etest.malt.rconll 8570 oldtags/bn/etest.mst.rconll 5438 oldtags/bn/etest.dz.rconll > $@
newtags/bn/dtest.voted.conll: newtags/bn/dtest.malt.rconll newtags/bn/dtest.mst.rconll newtags/bn/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8557 newtags/bn/dtest.malt.rconll 8570 newtags/bn/dtest.mst.rconll 5438 newtags/bn/dtest.dz.rconll > $@
newtags/bn/etest.voted.conll: newtags/bn/etest.malt.rconll newtags/bn/etest.mst.rconll newtags/bn/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8557 newtags/bn/etest.malt.rconll 8570 newtags/bn/etest.mst.rconll 5438 newtags/bn/etest.dz.rconll > $@

oldtags/te/dtest.voted.conll: oldtags/te/dtest.malt.rconll oldtags/te/dtest.mst.rconll oldtags/te/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8104 oldtags/te/dtest.malt.rconll 7985 oldtags/te/dtest.mst.rconll 4578 oldtags/te/dtest.dz.rconll > $@
oldtags/te/etest.voted.conll: oldtags/te/etest.malt.rconll oldtags/te/etest.mst.rconll oldtags/te/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8104 oldtags/te/etest.malt.rconll 7985 oldtags/te/etest.mst.rconll 4578 oldtags/te/etest.dz.rconll > $@
newtags/te/dtest.voted.conll: newtags/te/dtest.malt.rconll newtags/te/dtest.mst.rconll newtags/te/dtest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8104 newtags/te/dtest.malt.rconll 7985 newtags/te/dtest.mst.rconll 4578 newtags/te/dtest.dz.rconll > $@
newtags/te/etest.voted.conll: newtags/te/etest.malt.rconll newtags/te/etest.mst.rconll newtags/te/etest.dz.rconll $(TOOLDIR)/conll_vote.pl
	$(TOOLDIR)/conll_vote.pl 8104 newtags/te/etest.malt.rconll 7985 newtags/te/etest.mst.rconll 4578 newtags/te/etest.dz.rconll > $@

# This goal reconstructs the contents of the CoNLL fields that should not have
# been modified by the parser.
#
oldtags/hi/dtest.dz.rconll: oldtags/hi/dtest.conll oldtags/hi/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/dtest.dz.conll > $@
oldtags/hi/etest.dz.rconll: oldtags/hi/etest.conll oldtags/hi/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/etest.dz.conll > $@
oldtags/bn/dtest.dz.rconll: oldtags/bn/dtest.conll oldtags/bn/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/dtest.dz.conll > $@
oldtags/bn/etest.dz.rconll: oldtags/bn/etest.conll oldtags/bn/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/etest.dz.conll > $@
oldtags/te/dtest.dz.rconll: oldtags/te/dtest.conll oldtags/te/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/dtest.dz.conll > $@
oldtags/te/etest.dz.rconll: oldtags/te/etest.conll oldtags/te/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/etest.dz.conll > $@
newtags/hi/dtest.dz.rconll: newtags/hi/dtest.conll newtags/hi/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/dtest.dz.conll > $@
newtags/hi/etest.dz.rconll: newtags/hi/etest.conll newtags/hi/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/etest.dz.conll > $@
newtags/bn/dtest.dz.rconll: newtags/bn/dtest.conll newtags/bn/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/dtest.dz.conll > $@
newtags/bn/etest.dz.rconll: newtags/bn/etest.conll newtags/bn/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/etest.dz.conll > $@
newtags/te/dtest.dz.rconll: newtags/te/dtest.conll newtags/te/dtest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/dtest.dz.conll > $@
newtags/te/etest.dz.rconll: newtags/te/etest.conll newtags/te/etest.dz.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/etest.dz.conll > $@

oldtags/hi/dtest.malt.rconll: oldtags/hi/dtest.conll oldtags/hi/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/dtest.malt.conll > $@
oldtags/hi/etest.malt.rconll: oldtags/hi/etest.conll oldtags/hi/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/etest.malt.conll > $@
oldtags/bn/dtest.malt.rconll: oldtags/bn/dtest.conll oldtags/bn/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/dtest.malt.conll > $@
oldtags/bn/etest.malt.rconll: oldtags/bn/etest.conll oldtags/bn/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/etest.malt.conll > $@
oldtags/te/dtest.malt.rconll: oldtags/te/dtest.conll oldtags/te/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/dtest.malt.conll > $@
oldtags/te/etest.malt.rconll: oldtags/te/etest.conll oldtags/te/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/etest.malt.conll > $@
newtags/hi/dtest.malt.rconll: newtags/hi/dtest.conll newtags/hi/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/dtest.malt.conll > $@
newtags/hi/etest.malt.rconll: newtags/hi/etest.conll newtags/hi/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/etest.malt.conll > $@
newtags/bn/dtest.malt.rconll: newtags/bn/dtest.conll newtags/bn/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/dtest.malt.conll > $@
newtags/bn/etest.malt.rconll: newtags/bn/etest.conll newtags/bn/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/etest.malt.conll > $@
newtags/te/dtest.malt.rconll: newtags/te/dtest.conll newtags/te/dtest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/dtest.malt.conll > $@
newtags/te/etest.malt.rconll: newtags/te/etest.conll newtags/te/etest.malt.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/etest.malt.conll > $@

oldtags/hi/dtest.mst.rconll: oldtags/hi/dtest.conll oldtags/hi/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/dtest.mst.conll > $@
oldtags/hi/etest.mst.rconll: oldtags/hi/etest.conll oldtags/hi/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/etest.mst.conll > $@
oldtags/bn/dtest.mst.rconll: oldtags/bn/dtest.conll oldtags/bn/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/dtest.mst.conll > $@
oldtags/bn/etest.mst.rconll: oldtags/bn/etest.conll oldtags/bn/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/etest.mst.conll > $@
oldtags/te/dtest.mst.rconll: oldtags/te/dtest.conll oldtags/te/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/dtest.mst.conll > $@
oldtags/te/etest.mst.rconll: oldtags/te/etest.conll oldtags/te/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/etest.mst.conll > $@
newtags/hi/dtest.mst.rconll: newtags/hi/dtest.conll newtags/hi/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/dtest.mst.conll > $@
newtags/hi/etest.mst.rconll: newtags/hi/etest.conll newtags/hi/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/etest.mst.conll > $@
newtags/bn/dtest.mst.rconll: newtags/bn/dtest.conll newtags/bn/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/dtest.mst.conll > $@
newtags/bn/etest.mst.rconll: newtags/bn/etest.conll newtags/bn/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/etest.mst.conll > $@
newtags/te/dtest.mst.rconll: newtags/te/dtest.conll newtags/te/dtest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/dtest.mst.conll > $@
newtags/te/etest.mst.rconll: newtags/te/etest.conll newtags/te/etest.mst.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/etest.mst.conll > $@

oldtags/hi/dtest.voted.rconll: oldtags/hi/dtest.conll oldtags/hi/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/dtest.voted.conll > $@
oldtags/hi/etest.voted.rconll: oldtags/hi/etest.conll oldtags/hi/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/hi/etest.voted.conll > $@
oldtags/bn/dtest.voted.rconll: oldtags/bn/dtest.conll oldtags/bn/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/dtest.voted.conll > $@
oldtags/bn/etest.voted.rconll: oldtags/bn/etest.conll oldtags/bn/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/bn/etest.voted.conll > $@
oldtags/te/dtest.voted.rconll: oldtags/te/dtest.conll oldtags/te/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/dtest.voted.conll > $@
oldtags/te/etest.voted.rconll: oldtags/te/etest.conll oldtags/te/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s oldtags/te/etest.voted.conll > $@
newtags/hi/dtest.voted.rconll: newtags/hi/dtest.conll newtags/hi/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/dtest.voted.conll > $@
newtags/hi/etest.voted.rconll: newtags/hi/etest.conll newtags/hi/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/hi/etest.voted.conll > $@
newtags/bn/dtest.voted.rconll: newtags/bn/dtest.conll newtags/bn/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/dtest.voted.conll > $@
newtags/bn/etest.voted.rconll: newtags/bn/etest.conll newtags/bn/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/bn/etest.voted.conll > $@
newtags/te/dtest.voted.rconll: newtags/te/dtest.conll newtags/te/dtest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/dtest.voted.conll > $@
newtags/te/etest.voted.rconll: newtags/te/etest.conll newtags/te/etest.voted.conll
	$(TOOLDIR)/conll2006merge.pl -i $< -s newtags/te/etest.voted.conll > $@

# This goal evaluates parsed text and stores the evaluation in a file.
#
oldtags/hi/dtest.dz.eval.txt: oldtags/hi/dtest.conll oldtags/hi/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/hi/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/bn/dtest.dz.eval.txt: oldtags/bn/dtest.conll oldtags/bn/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/bn/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/te/dtest.dz.eval.txt: oldtags/te/dtest.conll oldtags/te/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/te/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/hi/dtest.dz.eval.txt: newtags/hi/dtest.conll newtags/hi/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/hi/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/bn/dtest.dz.eval.txt: newtags/bn/dtest.conll newtags/bn/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/bn/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/te/dtest.dz.eval.txt: newtags/te/dtest.conll newtags/te/dtest.dz.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/te/dtest.dz.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt

oldtags/hi/dtest.malt.eval.txt: oldtags/hi/dtest.conll oldtags/hi/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/hi/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/bn/dtest.malt.eval.txt: oldtags/bn/dtest.conll oldtags/bn/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/bn/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/te/dtest.malt.eval.txt: oldtags/te/dtest.conll oldtags/te/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/te/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/hi/dtest.malt.eval.txt: newtags/hi/dtest.conll newtags/hi/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/hi/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/bn/dtest.malt.eval.txt: newtags/bn/dtest.conll newtags/bn/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/bn/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/te/dtest.malt.eval.txt: newtags/te/dtest.conll newtags/te/dtest.malt.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/te/dtest.malt.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt

oldtags/hi/dtest.mst.eval.txt: oldtags/hi/dtest.conll oldtags/hi/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/hi/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/bn/dtest.mst.eval.txt: oldtags/bn/dtest.conll oldtags/bn/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/bn/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/te/dtest.mst.eval.txt: oldtags/te/dtest.conll oldtags/te/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/te/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/hi/dtest.mst.eval.txt: newtags/hi/dtest.conll newtags/hi/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/hi/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/bn/dtest.mst.eval.txt: newtags/bn/dtest.conll newtags/bn/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/bn/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/te/dtest.mst.eval.txt: newtags/te/dtest.conll newtags/te/dtest.mst.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/te/dtest.mst.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt

oldtags/hi/dtest.voted.eval.txt: oldtags/hi/dtest.conll oldtags/hi/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/hi/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/bn/dtest.voted.eval.txt: oldtags/bn/dtest.conll oldtags/bn/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/bn/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
oldtags/te/dtest.voted.eval.txt: oldtags/te/dtest.conll oldtags/te/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s oldtags/te/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/hi/dtest.voted.eval.txt: newtags/hi/dtest.conll newtags/hi/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/hi/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/bn/dtest.voted.eval.txt: newtags/bn/dtest.conll newtags/bn/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/bn/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt
newtags/te/dtest.voted.eval.txt: newtags/te/dtest.conll newtags/te/dtest.voted.rconll
	$(TOOLDIR)/conll-eval07.pl -g $< -s newtags/te/dtest.voted.rconll > $@
	@date >> eval.txt
	@echo $@ >> eval.txt
	@head -3 $@ >> eval.txt

# This goal checks the format of the data that shall be submitted to the organizers.
# (I am using a copy of the checking script that the organizers use.)
# The checking script seems to return 1 even if a file passes the check, so ignore the exit status.
#
oldtags/hi/dtest.voted.check.txt: oldtags/hi/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
oldtags/hi/etest.voted.check.txt: oldtags/hi/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
oldtags/bn/dtest.voted.check.txt: oldtags/bn/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
oldtags/bn/etest.voted.check.txt: oldtags/bn/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
oldtags/te/dtest.voted.check.txt: oldtags/te/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
oldtags/te/etest.voted.check.txt: oldtags/te/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/hi/dtest.voted.check.txt: newtags/hi/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/hi/etest.voted.check.txt: newtags/hi/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/bn/dtest.voted.check.txt: newtags/bn/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/bn/etest.voted.check.txt: newtags/bn/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/te/dtest.voted.check.txt: newtags/te/dtest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@
newtags/te/etest.voted.check.txt: newtags/te/etest.voted.rconll
	$(TOOLDIR)/validate_conll_2006_format.py -t system -s cycle $< > $@






###############################################################################
# The rest of this Makefile contains non-pattern rules for the individual data
# files. Mostly they deal with copying data from the original folders, packing
# them for submission, renaming to fit our naming conventions etc.
###############################################################################



# These goals rename the final data files and pack them as required by the organizers.
# Instructions:
# 1 zip file named according to the team login name, i.e. group3.zip
# inside of the zip file, there should be three files, one for each language
# multiple solutions can be uploaded as group3_1.zip, group3_2.zip etc.
#
ICON_SUBMIT_FILES = $(foreach round,$(ROUNDS),$(foreach lang,$(LANGS),submit/ICON2009-$(round)-$(lang)-group3.conll))
# The -j option strips path from the filenames.
group3.zip: $(ICON_SUBMIT_FILES)
	zip -ju $@ $^
submit/ICON2009-oldtags-hi-group3.conll: oldtags/hi/etest.voted.conll oldtags/hi/etest.voted.check.txt
	cp $< $@
submit/ICON2009-oldtags-bn-group3.conll: oldtags/bn/etest.voted.conll oldtags/bn/etest.voted.check.txt
	cp $< $@
submit/ICON2009-oldtags-te-group3.conll: oldtags/te/etest.voted.conll oldtags/te/etest.voted.check.txt
	cp $< $@
submit/ICON2009-newtags-hi-group3.conll: newtags/hi/etest.voted.conll newtags/hi/etest.voted.check.txt
	cp $< $@
submit/ICON2009-newtags-bn-group3.conll: newtags/bn/etest.voted.conll newtags/bn/etest.voted.check.txt
	cp $< $@
submit/ICON2009-newtags-te-group3.conll: newtags/te/etest.voted.conll newtags/te/etest.voted.check.txt
	cp $< $@
.PHONY: all_d
all_d: oldtags/hi/dtrain.rmconll oldtags/hi/dtest.rmconll oldtags/bn/dtrain.rmconll oldtags/bn/dtest.rmconll oldtags/te/dtrain.rmconll oldtags/te/dtest.rmconll newtags/hi/dtrain.rmconll newtags/hi/dtest.rmconll newtags/bn/dtrain.rmconll newtags/bn/dtest.rmconll newtags/te/dtrain.rmconll newtags/te/dtest.rmconll oldtags/hi/dtrain.csts oldtags/hi/dtest.csts oldtags/bn/dtrain.csts oldtags/bn/dtest.csts oldtags/te/dtrain.csts oldtags/te/dtest.csts newtags/hi/dtrain.csts newtags/hi/dtest.csts newtags/bn/dtrain.csts newtags/bn/dtest.csts newtags/te/dtrain.csts newtags/te/dtest.csts oldtags/hi/d.stat oldtags/bn/d.stat oldtags/te/d.stat newtags/hi/d.stat newtags/bn/d.stat newtags/te/d.stat oldtags/hi/dtest.dzg.csts oldtags/bn/dtest.dzg.csts oldtags/te/dtest.dzg.csts newtags/hi/dtest.dzg.csts newtags/bn/dtest.dzg.csts newtags/te/dtest.dzg.csts oldtags/hi/d.astat oldtags/bn/d.astat oldtags/te/d.astat newtags/hi/d.astat newtags/bn/d.astat newtags/te/d.astat oldtags/hi/dtest.dza.csts oldtags/bn/dtest.dza.csts oldtags/te/dtest.dza.csts newtags/hi/dtest.dza.csts newtags/bn/dtest.dza.csts newtags/te/dtest.dza.csts oldtags/hi/dtest.dz.conll oldtags/bn/dtest.dz.conll oldtags/te/dtest.dz.conll newtags/hi/dtest.dz.conll newtags/bn/dtest.dz.conll newtags/te/dtest.dz.conll oldtags/hi/d.mco newtags/hi/d.mco oldtags/bn/d.mco newtags/bn/d.mco oldtags/te/d.mco newtags/te/d.mco oldtags/hi/dtest.malt.conll newtags/hi/dtest.malt.conll oldtags/bn/dtest.malt.conll newtags/bn/dtest.malt.conll oldtags/te/dtest.malt.conll newtags/te/dtest.malt.conll oldtags/hi/d.mst oldtags/bn/d.mst oldtags/te/d.mst newtags/hi/d.mst newtags/bn/d.mst newtags/te/d.mst oldtags/hi/dtest.mst.conll oldtags/bn/dtest.mst.conll oldtags/te/dtest.mst.conll newtags/hi/dtest.mst.conll newtags/bn/dtest.mst.conll newtags/te/dtest.mst.conll oldtags/hi/dtest.malt.csts oldtags/bn/dtest.malt.csts oldtags/te/dtest.malt.csts newtags/hi/dtest.malt.csts newtags/bn/dtest.malt.csts newtags/te/dtest.malt.csts oldtags/hi/dtest.mst.csts oldtags/bn/dtest.mst.csts oldtags/te/dtest.mst.csts newtags/hi/dtest.mst.csts newtags/bn/dtest.mst.csts newtags/te/dtest.mst.csts oldtags/hi/dtest.dz.csts oldtags/bn/dtest.dz.csts oldtags/te/dtest.dz.csts newtags/hi/dtest.dz.csts newtags/bn/dtest.dz.csts newtags/te/dtest.dz.csts oldtags/hi/dtest.cmp.txt oldtags/bn/dtest.cmp.txt oldtags/te/dtest.cmp.txt newtags/hi/dtest.cmp.txt newtags/bn/dtest.cmp.txt newtags/te/dtest.cmp.txt oldtags/hi/dtest.voted.conll newtags/hi/dtest.voted.conll oldtags/bn/dtest.voted.conll newtags/bn/dtest.voted.conll oldtags/te/dtest.voted.conll newtags/te/dtest.voted.conll oldtags/hi/dtest.dz.rconll oldtags/bn/dtest.dz.rconll oldtags/te/dtest.dz.rconll newtags/hi/dtest.dz.rconll newtags/bn/dtest.dz.rconll newtags/te/dtest.dz.rconll oldtags/hi/dtest.malt.rconll oldtags/bn/dtest.malt.rconll oldtags/te/dtest.malt.rconll newtags/hi/dtest.malt.rconll newtags/bn/dtest.malt.rconll newtags/te/dtest.malt.rconll oldtags/hi/dtest.mst.rconll oldtags/bn/dtest.mst.rconll oldtags/te/dtest.mst.rconll newtags/hi/dtest.mst.rconll newtags/bn/dtest.mst.rconll newtags/te/dtest.mst.rconll oldtags/hi/dtest.voted.rconll oldtags/bn/dtest.voted.rconll oldtags/te/dtest.voted.rconll newtags/hi/dtest.voted.rconll newtags/bn/dtest.voted.rconll newtags/te/dtest.voted.rconll oldtags/hi/dtest.dz.eval.txt oldtags/bn/dtest.dz.eval.txt oldtags/te/dtest.dz.eval.txt newtags/hi/dtest.dz.eval.txt newtags/bn/dtest.dz.eval.txt newtags/te/dtest.dz.eval.txt oldtags/hi/dtest.malt.eval.txt oldtags/bn/dtest.malt.eval.txt oldtags/te/dtest.malt.eval.txt newtags/hi/dtest.malt.eval.txt newtags/bn/dtest.malt.eval.txt newtags/te/dtest.malt.eval.txt oldtags/hi/dtest.mst.eval.txt oldtags/bn/dtest.mst.eval.txt oldtags/te/dtest.mst.eval.txt newtags/hi/dtest.mst.eval.txt newtags/bn/dtest.mst.eval.txt newtags/te/dtest.mst.eval.txt oldtags/hi/dtest.voted.eval.txt oldtags/bn/dtest.voted.eval.txt oldtags/te/dtest.voted.eval.txt newtags/hi/dtest.voted.eval.txt newtags/bn/dtest.voted.eval.txt newtags/te/dtest.voted.eval.txt oldtags/hi/dtest.voted.check.txt oldtags/bn/dtest.voted.check.txt oldtags/te/dtest.voted.check.txt newtags/hi/dtest.voted.check.txt newtags/bn/dtest.voted.check.txt newtags/te/dtest.voted.check.txt
.PHONY: all_e
all_e: oldtags/hi/etrain.rmconll oldtags/hi/etest.rmconll oldtags/bn/etrain.rmconll oldtags/bn/etest.rmconll oldtags/te/etrain.rmconll oldtags/te/etest.rmconll newtags/hi/etrain.rmconll newtags/hi/etest.rmconll newtags/bn/etrain.rmconll newtags/bn/etest.rmconll newtags/te/etrain.rmconll newtags/te/etest.rmconll oldtags/hi/etrain.csts oldtags/hi/etest.csts oldtags/bn/etrain.csts oldtags/bn/etest.csts oldtags/te/etrain.csts oldtags/te/etest.csts newtags/hi/etrain.csts newtags/hi/etest.csts newtags/bn/etrain.csts newtags/bn/etest.csts newtags/te/etrain.csts newtags/te/etest.csts oldtags/hi/e.stat oldtags/bn/e.stat oldtags/te/e.stat newtags/hi/e.stat newtags/bn/e.stat newtags/te/e.stat oldtags/hi/etest.dzg.csts oldtags/bn/etest.dzg.csts oldtags/te/etest.dzg.csts newtags/hi/etest.dzg.csts newtags/bn/etest.dzg.csts newtags/te/etest.dzg.csts oldtags/hi/e.astat oldtags/bn/e.astat oldtags/te/e.astat newtags/hi/e.astat newtags/bn/e.astat newtags/te/e.astat oldtags/hi/etest.dza.csts oldtags/bn/etest.dza.csts oldtags/te/etest.dza.csts newtags/hi/etest.dza.csts newtags/bn/etest.dza.csts newtags/te/etest.dza.csts oldtags/hi/etest.dz.conll oldtags/bn/etest.dz.conll oldtags/te/etest.dz.conll newtags/hi/etest.dz.conll newtags/bn/etest.dz.conll newtags/te/etest.dz.conll oldtags/hi/e.mco newtags/hi/e.mco oldtags/bn/e.mco newtags/bn/e.mco oldtags/te/e.mco newtags/te/e.mco oldtags/hi/etest.malt.conll newtags/hi/etest.malt.conll oldtags/bn/etest.malt.conll newtags/bn/etest.malt.conll oldtags/te/etest.malt.conll newtags/te/etest.malt.conll oldtags/hi/e.mst oldtags/bn/e.mst oldtags/te/e.mst newtags/hi/e.mst newtags/bn/e.mst newtags/te/e.mst oldtags/hi/etest.mst.conll oldtags/bn/etest.mst.conll oldtags/te/etest.mst.conll newtags/hi/etest.mst.conll newtags/bn/etest.mst.conll newtags/te/etest.mst.conll oldtags/hi/etest.malt.csts oldtags/bn/etest.malt.csts oldtags/te/etest.malt.csts newtags/hi/etest.malt.csts newtags/bn/etest.malt.csts newtags/te/etest.malt.csts oldtags/hi/etest.mst.csts oldtags/bn/etest.mst.csts oldtags/te/etest.mst.csts newtags/hi/etest.mst.csts newtags/bn/etest.mst.csts newtags/te/etest.mst.csts oldtags/hi/etest.dz.csts oldtags/bn/etest.dz.csts oldtags/te/etest.dz.csts newtags/hi/etest.dz.csts newtags/bn/etest.dz.csts newtags/te/etest.dz.csts oldtags/hi/etest.cmp.txt oldtags/bn/etest.cmp.txt oldtags/te/etest.cmp.txt newtags/hi/etest.cmp.txt newtags/bn/etest.cmp.txt newtags/te/etest.cmp.txt oldtags/hi/etest.voted.conll newtags/hi/etest.voted.conll oldtags/bn/etest.voted.conll newtags/bn/etest.voted.conll oldtags/te/etest.voted.conll newtags/te/etest.voted.conll oldtags/hi/etest.dz.rconll oldtags/bn/etest.dz.rconll oldtags/te/etest.dz.rconll newtags/hi/etest.dz.rconll newtags/bn/etest.dz.rconll newtags/te/etest.dz.rconll oldtags/hi/etest.malt.rconll oldtags/bn/etest.malt.rconll oldtags/te/etest.malt.rconll newtags/hi/etest.malt.rconll newtags/bn/etest.malt.rconll newtags/te/etest.malt.rconll oldtags/hi/etest.mst.rconll oldtags/bn/etest.mst.rconll oldtags/te/etest.mst.rconll newtags/hi/etest.mst.rconll newtags/bn/etest.mst.rconll newtags/te/etest.mst.rconll oldtags/hi/etest.voted.rconll oldtags/bn/etest.voted.rconll oldtags/te/etest.voted.rconll newtags/hi/etest.voted.rconll newtags/bn/etest.voted.rconll newtags/te/etest.voted.rconll oldtags/hi/etest.voted.check.txt oldtags/bn/etest.voted.check.txt oldtags/te/etest.voted.check.txt newtags/hi/etest.voted.check.txt newtags/bn/etest.voted.check.txt newtags/te/etest.voted.check.txt
