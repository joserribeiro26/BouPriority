# --
# Copyright (C) 2015-2016 BeOnUp http://www.beonup.com.br
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilter::AgentEasyCategorization;

use strict;
use warnings;

use List::Util qw(first);
use Kernel::System::EmailParser;
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Encode
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::Time
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

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

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
        UserID        => $Self->{UserID},
        Silent        => 1, 
    );

    # get config of frontend module
    my $Config = $ConfigObject->Get("Ticket::Frontend::AgentTicketNote");

    # get ACL restrictions
    my %PossibleActions = ( 1 => $Self->{Action} );

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );

    my %AclAction = $TicketObject->TicketAclActionData();

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

    # get dynamic field values form http request
    my %DynamicFieldValues;

    # to store the reference to the dynamic field for the impact

    # define the dynamic fields to show based on the object type
    my $ObjectType = ['Ticket'];

    # only screens that add notes can modify Article dynamic fields
    if ( $Config->{Note} ) {
        $ObjectType = [ 'Ticket', 'Article' ];
    }

    my %DynamicFieldHTML;
    my $Output;
    my %Data;

    if ( $ConfigObject->Get('EasyCategorization::Type') ){
        my $Types = $Self->_GetTypes(
            %GetParam,
            TicketID => $Self->{TicketID},
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
            OnChange    => "this.form.submit();",
        );

        $LayoutObject->Block(
            Name => 'Type',
            Data => {%Data},
        );
    }

    if ( $ConfigObject->Get('EasyCategorization::Service') ){

        my $Services = $Self->_GetServices(
            %GetParam,
            TicketID       => $Self->{TicketID},
            CustomerUserID => $Ticket{CustomerUserID},
            QueueID        => $Ticket{QueueID},
        );

        my $SLAs = $Self->_GetSLAs(
            %GetParam,
            QueueID        => $Ticket{QueueID},
            ServiceID      => $Ticket{ServiceID},
            CustomerUserID => $Ticket{CustomerUserID},
        );

        $Data{ServiceSrt} = $LayoutObject->BuildSelection(
            Data        => $Services,
            Name        => 'ServiceID',
            SelectedID  => $Ticket{ServiceID},
            Size        => 5,
            Multiple    => 0,
            TreeView    => 1,
            Translation => 0,
            Max         => 50,
            Class       => 'Modernize',
            OnChange    => "this.form.submit();",
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
            OnChange    => "this.form.submit();",
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
        my $Priorities = $Self->_GetPriorities(
            %GetParam,
            TicketID => $Self->{TicketID},
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
            OnChange    => "this.form.submit();",
        );

        $LayoutObject->Block(
            Name => 'Priority',
            Data => {%Data},
        );
    }

    my $iFrame = $LayoutObject->Output(
        TemplateFile => 'AgentEasyCategorization',
        Data         => \%Data,
    );
    ${ $Param{Data} } =~ s{(<div \s+ id="ArticleTree">)}{$iFrame $1}xms;

    return ${ $Param{Data} };
}


sub _GetNextStates {
    my ( $Self, %Param ) = @_;

    my %NextStates = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateList(
        TicketID => $Self->{TicketID},
        Action   => $Self->{Action},
        UserID   => $Self->{UserID},
        %Param,
    );

    return \%NextStates;
}

sub _GetResponsible {    
    my ( $Self, %Param ) = @_;
    my %ShownUsers;
    my %AllGroupsMembers = $Kernel::OM->Get('Kernel::System::User')->UserList(
        Type  => 'Long',
        Valid => 1,
    );

    # show all users
    if ( $Kernel::OM->Get('Kernel::Config')->Get('Ticket::ChangeOwnerToEveryone') ) {
        %ShownUsers = %AllGroupsMembers;
    }

    # show only users with responsible or rw pemissions in the queue
    elsif ( $Param{QueueID} && !$Param{AllUsers} ) {
        my $GID = $Kernel::OM->Get('Kernel::System::Queue')->GetQueueGroupID(
            QueueID => $Param{NewQueueID} || $Param{QueueID}
        );
        my %MemberList = $Kernel::OM->Get('Kernel::System::Group')->PermissionGroupGet(
            GroupID => $GID,
            Type    => 'responsible',
        );
        for my $UserID ( sort keys %MemberList ) {
            $ShownUsers{$UserID} = $AllGroupsMembers{$UserID};
        }
    }

    # get ticket object
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # workflow
    my $ACL = $TicketObject->TicketAcl(
        %Param,
        Action        => $Self->{Action},
        ReturnType    => 'Ticket',
        ReturnSubType => 'Responsible',
        Data          => \%ShownUsers,
        UserID        => $Self->{UserID},
    );

    return { $TicketObject->TicketAclData() } if $ACL;

    return \%ShownUsers;
}

sub _GetServices {
    my ( $Self, %Param ) = @_;

    # get service
    my %Service;

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # check if no CustomerUserID is selected
    # if $DefaultServiceUnknownCustomer = 0 leave CustomerUserID empty, it will not get any services
    # if $DefaultServiceUnknownCustomer = 1 set CustomerUserID to get default services
    if ( !$Param{CustomerUserID} && $DefaultServiceUnknownCustomer ) {
        $Param{CustomerUserID} = '<DEFAULT>';
    }

    # get service list
    if ( $Param{CustomerUserID} ) {
        %Service = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Service;
}

sub _GetSLAs {
    my ( $Self, %Param ) = @_;

    # if non set customers can get default services then they should also be able to get the SLAs
    #  for those services (this works during ticket creation).
    # if no CustomerUserID is set, TicketSLAList will complain during AJAX updates as UserID is not
    #  passed. See bug 11147.

    # get options for default services for unknown customers
    my $DefaultServiceUnknownCustomer
        = $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Service::Default::UnknownCustomer');

    # check if no CustomerUserID is selected
    # if $DefaultServiceUnknownCustomer = 0 leave CustomerUserID empty, it will not get any services
    # if $DefaultServiceUnknownCustomer = 1 set CustomerUserID to get default services
    if ( !$Param{CustomerUserID} && $DefaultServiceUnknownCustomer ) {
        $Param{CustomerUserID} = '<DEFAULT>';
    }

    my %SLA;
    if ( $Param{ServiceID} ) {
        %SLA = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSLAList(
            %Param,
            Action => $Self->{Action},
        );
    }
    return \%SLA;
}

sub _GetPriorities {
    my ( $Self, %Param ) = @_;

    my %Priorities = $Kernel::OM->Get('Kernel::System::Ticket')->TicketPriorityList(
        %Param,
        Action   => $Self->{Action},
        UserID   => $Self->{UserID},
        TicketID => $Self->{TicketID},
    );

    # get config of frontend module
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::$Self->{Action}");

    if ( !$Config->{PriorityDefault} ) {
        $Priorities{''} = '-';
    }
    return \%Priorities;
}

sub _GetTypes {
    my ( $Self, %Param ) = @_;

    # get type
    my %Type;
    if ( $Param{QueueID} || $Param{TicketID} ) {
        %Type = $Kernel::OM->Get('Kernel::System::Ticket')->TicketTypeList(
            %Param,
            Action => $Self->{Action},
            UserID => $Self->{UserID},
        );
    }
    return \%Type;
}

1;
