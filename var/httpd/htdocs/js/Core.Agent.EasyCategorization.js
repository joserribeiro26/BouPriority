// --
// Copyright (C) 2015-2017 BeOnUp, http://beonup.com.br/
//
// written/edited by:
// * pdias@beonup.com.br
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};

/**
 * @namespace Core.Agent.EasyCategorization
 * @memberof Core.Agent
 * @author pdias@beonup.com.br
 * @description
 *      This namespace contains the special module functions for EasyCategorization.
 */
Core.Agent.EasyCategorization = (function (TargetNS) {  
    
	/**
     * @name TypeUpdate
     * @memberof Core.Agent.EasyCategorization
     * @function
     * @param {String}
     * @description
     *      This function gets service data.
     */
	
	TargetNS.TypeUpdate = function (TicketID) {
        var Data = {
            Action: 'EasyCategorizationAJAXHandler',
            Subaction: 'TypeUpdate',
			TypeID: $('#TypeID').val(),
			TicketID: TicketID,
        };
		
		Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Result) {						
			if (!Result){
				Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Error! No server response.", 'CommunicationError'));
			}
			else{
				var SelectData = JSON.parse(Result.JSONString);
				
				UpdateFormElements(SelectData);
				
				$("#AJAXLoaderTypeID").css("display", "none");
				
				if ($('#ServiceID option').length == 1) {
					$('#ServiceID').attr("readonly", "true");
				}
				else{
					$('#ServiceID').attr("readonly", "false");
				}
			}
		}); 
	}
	
	/**
     * @name ServiceUpdate
     * @memberof Core.Agent.EasyCategorization
     * @function
     * @param {String}
     * @description
     *      This function gets service data.
     */
	 
	TargetNS.ServiceUpdate = function (TicketID) {
        var Data = {
            Action: 'EasyCategorizationAJAXHandler',
            Subaction: 'ServiceUpdate',
			ServiceID: $('#ServiceID').val(),
			TicketID: TicketID,
        };
		
		Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Result) {						
			if (!Result){
				Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Error! No server response.", 'CommunicationError'));
			}
			else{
				var SelectData = JSON.parse(Result.JSONString);
				UpdateFormElements(SelectData);
				$("#AJAXLoaderServiceID").css("display", "none");
				
				if ($('#SLAID option').length == 1) {
					$('#SLAID').attr("readonly", "true");
				}
				else{
					$('#SLAID_Search').attr("readonly", false);
					$('#SLAID').attr("readonly", false);
				}
			}
		}); 
	}
	
	/**
     * @name SLAUpdate
     * @memberof Core.Agent.EasyCategorization
     * @function
     * @param {String}
     * @description
     *      This function gets service data.
     */
	
	TargetNS.SLAUpdate = function (TicketID) {
        var Data = {
            Action: 'EasyCategorizationAJAXHandler',
            Subaction: 'SLAUpdate',
			SLAID: $('#SLAID').val(),
			TicketID: TicketID,
        };
		
		Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Result) {
			if (!Result){
				Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Error! No server response.", 'CommunicationError'));
			}
			else{
				$("#AJAXLoaderSLAID").css("display", "none");
			}
		}); 
	}
	
	/**
     * @name PriorityUpdate
     * @memberof Core.Agent.EasyCategorization
     * @function
     * @param {String}
     * @description
     *      This function gets service data.
     */
	
	TargetNS.PriorityUpdate = function (TicketID) {
        var Data = {
            Action: 'EasyCategorizationAJAXHandler',
            Subaction: 'PriorityUpdate',
			PriorityID: $('#PriorityID').val(),
			TicketID: TicketID,
        };
		
		Core.AJAX.FunctionCall(Core.Config.Get('CGIHandle'), Data, function (Result) {
			if (!Result){
				Core.Exception.HandleFinalError(new Core.Exception.ApplicationError("Error! No server response.", 'CommunicationError'));
			}
			else{
				$("#AJAXLoaderPriorityID").css("display", "none");
			}
		});
	}
	
	/**
     * @private
     * @name UpdateFormElements
     * @function
     * @param {Object} Data - The new field data. The keys are the IDs of the fields to be updated.
     * @description
     *      Updates the given fields with the given data.
     */
	 
	function UpdateFormElements(Data) {
		$.each(Data, function (Field, DataValue) {
			var $Element = $('#' + Field);
			// Select elements
			if ($Element.is('select')) {
				$Element.empty();
				$.each(DataValue, function (Index, Value) {
					var NewOption,
						OptionText = Core.App.EscapeHTML(Value[1]);
			
					NewOption = new Option(OptionText, Value[0], Value[2], Value[3]);
			
					// Overwrite option text, because of wrong html quoting of text content.
					// (This is needed for IE.)
					NewOption.innerHTML = OptionText;
					$Element.append(NewOption);
			
				});
			
				// Trigger custom redraw event for InputFields
				if ($Element.hasClass('Modernize')) {
					$Element.trigger('redraw.InputField');
				}
			
				return;
			}
		});
	}

    return TargetNS;
}(Core.Agent.EasyCategorization || {}));
