# --
# Copyright (C) 2015-2016 BeOnUp http://www.beonup.com.br
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentEasyCategorization;

use strict;
use warnings;

use Kernel::System::EmailParser;
use Kernel::System::VariableCheck qw(:all);
use Data::Dumper;

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam;
    for my $Key (
        qw(
        NewStateID NewPriorityID TimeUnits ArticleTypeID Title Body Subject NewQueueID
        Year Month Day Hour Minute NewOwnerID NewResponsibleID TypeID ServiceID SLAID
        Expand ReplyToArticle StandardTemplateID CreateArticle
        )
        ) {
            $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }

    my $Success1 = $TicketObject->TicketTypeSet(
        TypeID    => $GetParam{TypeID},
        TicketID  => $Self->{TicketID},
        UserID    => $Self->{UserID},
    );

    my $Success2 = $TicketObject->TicketServiceSet(
        ServiceID => $GetParam{ServiceID},
        TicketID  => $Self->{TicketID},
        UserID    => $Self->{UserID},
    );

    my $Success3 = $TicketObject->TicketSLASet(
        SLAID     => $GetParam{SLAID},
        TicketID  => $Self->{TicketID},
        UserID    => $Self->{UserID},
    );

    my $Success4 = $TicketObject->TicketPrioritySet(
        PriorityID => $GetParam{SLAID},
        TicketID   => $Self->{TicketID},
        UserID     => $Self->{UserID},
    );

    my $HTML = $LayoutObject->Redirect(
        OP => "Action=AgentTicketZoom;TicketID=$Self->{TicketID}",
    );

    return $HTML;
}
