# --
# Kernel/Modules/EasyCategorizationAJAXHandler.pm - a module used to handle ajax requests
# Copyright (C) 2015-2017 BeOnUp, http://www.beonup.com.br
#
# written/edited by:
# * pdias@beonup.com.br
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --


package Kernel::Modules::EasyCategorizationAJAXHandler;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

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

    # create needed objects
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	my $EasyCategorizationObject = $Kernel::OM->Get('Kernel::System::EasyCategorization');
	my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
	
    my $JSON = '';
	
	my %GetParam;
    for my $Key ( qw( TypeID TicketID ServiceID SLAID PriorityID ) ){
        $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
    }
	
	my %Ticket = $TicketObject->TicketGet(
		TicketID      => $GetParam{TicketID},
		UserID        => $Self->{UserID},
		Silent        => 1, 
	);
	
	# get Type JSON
    if ( $Self->{Subaction} eq 'TypeUpdate' ) {
	
		my @DataView;
		my %JSONView;
		
		$Self->_ClearServiceAndSLA( UserID => $Self->{UserID}, TicketID => $GetParam{TicketID} );
		
		my $Success = $TicketObject->TicketTypeSet(
			TypeID   => $GetParam{TypeID},
			TicketID  => $GetParam{TicketID},
			UserID    => $Self->{UserID},
		);
		
		if ( $Success ){
			$LogObject->Log(
				Type => 'notice',
				Message => "New Type set where TicketID = $GetParam{TicketID}",
			);
		}
		
		my $ServiceList = $EasyCategorizationObject->GetServiceList(
            %GetParam,
            CustomerUserID	=> $Ticket{CustomerUserID},
            QueueID			=> $Ticket{QueueID}
        );
		
		my @PossibleNone = ('','-','true','false','false');
		push @DataView, \@PossibleNone;

		foreach my $ServiceID ( sort keys %$ServiceList ){
		
			my @DataSelect = ();
			
			@DataSelect = ($ServiceID,$ServiceList->{$ServiceID},'false','false','false');
			push @DataView, \@DataSelect;
		}
		
		$JSONView{'ServiceID'} = \@DataView;
		
		$JSONView{'SLAID'} = [\@PossibleNone];

		my $JSONString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
			Data     => \%JSONView
		);
		
		# replace boolean to no quotes
		$JSONString =~ s/"true"/true/g;
		$JSONString =~ s/"false"/false/g;

        # build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => {
                JSONString => $JSONString,
            },
        );
    }
	
	# get Service JSON
	elsif ( $Self->{Subaction} eq 'ServiceUpdate' ){
	
		my @DataView;
		my %JSONView;
		
		# clear set values 
		$Self->_ClearServiceAndSLA( UserID => $Self->{UserID}, TicketID => $GetParam{TicketID} );
		
		my $Success = $TicketObject->TicketServiceSet(
			ServiceID => $GetParam{ServiceID},
			TicketID  => $GetParam{TicketID},
			UserID    => $Self->{UserID},
		);
		
		if ( $Success ){
			$LogObject->Log(
				Type => 'notice',
				Message => "New Service set where TicketID = $GetParam{TicketID}",
			);
		}
		
		my $SLAs = $EasyCategorizationObject->GetSLAList(
			%GetParam,
            QueueID      	=> $Ticket{QueueID},
            ServiceID      	=> $GetParam{ServiceID},
            CustomerUserID 	=> $Ticket{CustomerUserID},
        );
		
		my @PossibleNone = ('','-','true','false','false');
		push @DataView, \@PossibleNone;

		foreach my $SLAID ( sort keys %$SLAs ){
		
			my @DataSelect = ();
			
			@DataSelect = ($SLAID,$SLAs->{$SLAID},'false','false','false');
			push @DataView, \@DataSelect;
		}

		$JSONView{'SLAID'} = \@DataView;
		
		my $JSONString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
			Data     => \%JSONView
		);
		
		# replace boolean to no quotes
		$JSONString =~ s/"true"/true/g;
		$JSONString =~ s/"false"/false/g;

        # build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => {
                JSONString => $JSONString,
            },
        );
	}
	
	# get SLA JSON
	elsif ( $Self->{Subaction} eq 'SLAUpdate' ){
		
		my $Success = $TicketObject->TicketSLASet(
			SLAID    => $GetParam{SLAID},
			TicketID  => $GetParam{TicketID},
			UserID    => $Self->{UserID},
		);
		
		if ( $Success ){
			$LogObject->Log(
				Type => 'notice',
				Message => "New SLA set where TicketID = $GetParam{TicketID}",
			);
		}
		
		my $JSONString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
			Data     => {Success => $Success}
		);
		
		# build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => {
                JSONString => $JSONString,
            },
        );
	}
	
	# get Priority JSON
	elsif ( $Self->{Subaction} eq 'PriorityUpdate' ){
	
		my $Success = $TicketObject->TicketPrioritySet(
			PriorityID => $GetParam{PriorityID},
			TicketID   => $GetParam{TicketID},
			UserID     => $Self->{UserID},
		);
		
		if ( $Success ){
			$LogObject->Log(
				Type => 'notice',
				Message => "New Priority set where TicketID = $GetParam{TicketID}",
			);
		}
		
		my $JSONString = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
			Data     => {Success => $Success}
		);
		
		# build JSON output
        $JSON = $LayoutObject->JSONEncode(
            Data => {
                JSONString => $JSONString,
            },
        );
	}
	
		
    # send JSON response
    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 1,
    );
}

sub _ClearServiceAndSLA{
	my ( $Self, %Param ) = @_;
	
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	
	$TicketObject->TicketSLASet(
		SLA      => 'NULL',
		TicketID => $Param{TicketID},
		UserID   => $Param{UserID},
	);
	
	$TicketObject->TicketServiceSet(
        Service  => 'NULL',
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );
	
	return 1;
}

1;