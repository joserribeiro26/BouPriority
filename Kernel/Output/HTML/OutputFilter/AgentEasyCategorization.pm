# --
# Copyright (C) 2015-2017 BeOnUp http://www.beonup.com.br
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilter::AgentEasyCategorization;

use strict;
use warnings;

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

    # get needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
	my $EasyCategorizationObject = $Kernel::OM->Get('Kernel::System::EasyCategorization');

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
        UserID        => $Self->{UserID},
        Silent        => 1, 
    );

    # get ACL restrictions
    my %PossibleActions = ( 1 => $Self->{Action} );

    $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );

    $TicketObject->TicketAclActionData();

    my %GetParam;
    for my $Key (
        qw(
        NewStateID NewPriorityID TimeUnits ArticleTypeID Title Subject NewQueueID
        Year Month Day Hour Minute NewOwnerID NewResponsibleID TypeID ServiceID SLAID
        Expand ReplyToArticle StandardTemplateID CreateArticle CustomerUser
        )
        )
    {
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }
	
	# data structure
    my %Data;

    if ( $ConfigObject->Get('EasyCategorization::Type') ){
        my $Types = $EasyCategorizationObject->GetTypeList(
            %GetParam,
            TicketID => $Self->{TicketID},
			UserID   => $Self->{UserID}
        );

        $Data{TypeStrg} = $LayoutObject->BuildSelection(
            Data        => $Types,
            Name        => 'TypeID',
            SelectedID  => $Ticket{TypeID},
            Size        => 5,
            Multiple    => 0,
            TreeView    => 1,
            Translation => 0,
            Max         => 50,
            Class       => 'Modernize',
        );

        $LayoutObject->Block(
            Name => 'Type',
            Data => {%Data},
        );
    }

    if ( $ConfigObject->Get('EasyCategorization::Service') ){

        my $Services = $EasyCategorizationObject->GetServiceList(
            %GetParam,
            TicketID       => $Self->{TicketID},
            CustomerUserID => $Ticket{CustomerUserID},
            QueueID        => $Ticket{QueueID},
			Action		   => $Self->{Action}
        );

        my $SLAs = $EasyCategorizationObject->GetSLAList(
            %GetParam,
            QueueID        => $Ticket{QueueID},
            ServiceID      => $Ticket{ServiceID},
            CustomerUserID => $Ticket{CustomerUserID}
        );

        $Data{ServiceSrtg} = $LayoutObject->BuildSelection(
            Data        => $Services,
            Name        => 'ServiceID',
            SelectedID  => $Ticket{ServiceID},
            Size        => 5,
            Multiple    => 0,
            TreeView    => 1,
            Translation => 0,
            Max         => 50,
            Class       => 'Modernize',
        );

        $Data{SLAStrg} .= $LayoutObject->BuildSelection(
            Data        => $SLAs,
            Name        => 'SLAID',
            SelectedID  => $Ticket{SLAID},
            Size        => 5,
            Multiple    => 0,
            TreeView    => 1,
            Translation => 0,
            Max         => 50,
            Class       => 'Modernize',
        );

        $LayoutObject->Block(
            Name => 'Service',
            Data => {%Data},
        );

        $LayoutObject->Block(
            Name => 'SLA',
            Data => {%Data},
        );
    }

    if ( $ConfigObject->Get('EasyCategorization::Priority') ){
        my $Priorities = $EasyCategorizationObject->GetPriorityList(
            %GetParam,
            TicketID => $Self->{TicketID},
			Action	 => $Self->{Action},
			UserID   => $Self->{UserID},
        );

        $Data{PriorityStrg} = $LayoutObject->BuildSelection(
            Data        => $Priorities,
            Name        => 'PriorityID',
            SelectedID  => $Ticket{PriorityID},
            Size        => 5,
            Multiple    => 0,
            TreeView    => 1,
            Translation => 1,
            Max         => 50,
            Class       => 'Modernize',
        );

        $LayoutObject->Block(
            Name => 'Priority',
            Data => {%Data},
        );
    }

    my $Frame = $LayoutObject->Output(
        TemplateFile => 'AgentEasyCategorization',
        Data         => \%Data,
    );
    ${ $Param{Data} } =~ s{(<div \s+ id="ArticleTree">)}{$Frame $1}xms;
	
	#Load JS time execution
	my $ZoomFrontendConfiguration = $ConfigObject->Get('Frontend::Module')->{AgentTicketZoom};
    my @CustomJSFiles = ('Core.Agent.EasyCategorization.js');
    push( @{ $ZoomFrontendConfiguration->{Loader}->{JavaScript} || [] }, @CustomJSFiles );
	
    # add js function to TypeID
	my $JSBlock = <<"JS_TYPE_BLOCK";
\$("#TypeID").bind('change', function () {
	\$("#AJAXLoaderTypeID").css("display","");
	
	// Update Type and load Services data
    Core.Agent.EasyCategorization.TypeUpdate($Self->{TicketID});
});
JS_TYPE_BLOCK
	
	# add js function to ServiceID
	$JSBlock .= <<"JS_SERVICE_BLOCK";
\$("#ServiceID").bind('change', function () {
	\$("#AJAXLoaderServiceID").css("display","");
	
	// Update service and load SLA data based
    Core.Agent.EasyCategorization.ServiceUpdate($Self->{TicketID});
});
JS_SERVICE_BLOCK

	# add js function to SLAID
	$JSBlock .= <<"JS_SLA_BLOCK";
\$("#SLAID").bind('change', function () {
	\$("#AJAXLoaderSLAID").css("display","");

	// Set value to SLA
    Core.Agent.EasyCategorization.SLAUpdate($Self->{TicketID});
});
JS_SLA_BLOCK

	# add js function to PriorityID
	$JSBlock .= <<"JS_PRIORITY_BLOCK";
\$("#PriorityID").bind('change', function () {
	\$("#AJAXLoaderPriorityID").css("display","");
	
	// Set value to Priority
    Core.Agent.EasyCategorization.PriorityUpdate($Self->{TicketID});
});
JS_PRIORITY_BLOCK

    $Self->AddJSOnDocumentCompleteIfNotExists(
        Key  => 'EasyCategorization',
        Code => $JSBlock,
    );

    return ${ $Param{Data} };
}

# --
# Function based on module Znuny4OTRS-Repo from Znuny
# --

sub AddJSOnDocumentCompleteIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Key Code)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Exists = 0;
    CODEJS:
    for my $CodeJS ( @{ $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{_JSOnDocumentComplete} || [] } ) {

        next CODEJS if $CodeJS !~ m{ Key: \s $Param{Key}}xms;
        $Exists = 1;
        last CODEJS;
    }

    return 1 if $Exists;

    my $AddCode = "// Key: $Param{Key}\n" . $Param{Code}."\n";

    $Kernel::OM->Get('Kernel::Output::HTML::Layout')->AddJSOnDocumentComplete(
        Code => $AddCode,
    );

    return 1;
}

1;
