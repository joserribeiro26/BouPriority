# --
# Kernel/Language/pt_BR_EasyCategorization.pm - the Portuguese translation for EasyCategorization
# Copyright (C) 2015-2016 BeOnUp http://www.beonup.com.br
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::pt_BR_EasyCategorization;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/EasyCategorization.xml
    $Lang->{'Module to show ticket categorization.'} = '';
    $Lang->{'Easy to classify your tickets.'} = '';
    $Lang->{'Easy Categorization'} = 'Categorização Fácil';
    $Lang->{'Easy categorization for the service.'} = 'Serviço na categorização fácil.';
    $Lang->{'Easy categorization for the type.'} = 'Tipo na categorização fácil.';
    $Lang->{'Easy categorization for the priority.'} = 'Prioridade na categorização fácil.';

    return 1;
}

1;
