# --
# Kernel/Language/hu_EasyCategorization.pm - the Hungarian translation for EasyCategorization
# Copyright (C) 2015-2017 BeOnUp http://www.beonup.com.br
# Copyright (C) 2016-2017 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_EasyCategorization;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/EasyCategorization.xml
    $Lang->{'Module to show ticket categorization.'} = 'Egy modul a jegykategorizálás megjelenítéséhez.';
    $Lang->{'Easy to classify your tickets.'} = 'Egyszerűen kategorizálhatóvá teszi a jegyeit.';
    $Lang->{'Easy Categorization'} = 'Egyszerű kategorizálás';
    $Lang->{'Easy categorization for the service.'} = 'A szolgáltatás egyszerű kategorizálása.';
    $Lang->{'Easy categorization for the type.'} = 'A típus egyszerű kategorizálása.';
    $Lang->{'Easy categorization for the priority.'} = 'A prioritás egyszerű kategorizálása.';
    $Lang->{'Frontend module registration for the agent interface.'} =
        'Előtétprogram-modul regisztráció az ügyintézői felülethez.';
    $Lang->{'To perform easy categorization with AJAX-request.'} =
        'Az egyszerű kategorizálás végrehajtásához AJAX kéréssel.';
    $Lang->{'EasyCategorization AJAX'} = 'Egyszerű kategorizálás AJAX';

    return 1;
}

1;
