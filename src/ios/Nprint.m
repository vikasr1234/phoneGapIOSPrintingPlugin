
#import <Cordova/CDVAvailability.h>
#import "ePOS2.h"
#import "NPrint.h"

@interface NPrinter () <Epos2DiscoveryDelegate, Epos2PtrReceiveDelegate>
    Epos2Printer *printer_;
    - (void) sendError:(int)errorStatus textForShow:(NSString*)text command:(CDVInvokedUrlCommand*)command;
    - (void) sendError:(NSString*)text command:(CDVInvokedUrlCommand*)command;
@end


@implementation NPrinter
/**
 * Find printers and print
 * Sends the printing content to the printer controller and opens them.
 *
 */

- (void) getAvailablePrinters:(CDVInvokedUrlCommand*)command
{
    Epos2FilterOption *option = [Epos2FilterOption alloc] init];
    [Epos2Discovery start:option delegate:self];

    // searching
    [Epos2Discovery stop];

    Epos2DeviceInfo* targetPrinter = [NSObject alloc];

    if (targetPrinter == nil) {
        [self sendError:@"printers not found" command:command];
    } else {
        NSMutableArray *listForSend = [[NSMutableArray alloc] init];

        for (int i = 0; i < [printerList_ count]; i++) {
            [listForSend addObject:[targetPrinter printerName]];
        }

        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                         messageAsArray:listForSend];

        [self.commandDelegate sendPluginResult:pluginResult
                              callbackId:command.callbackId];
    }
}


- (void) print:(CDVInvokedUrlCommand*)command
{
    [printer_ setReceiveEventDelegate:self];
    [targetPrinter_ setDiscoveryEventDelegate:self];

    NSArray * arguments = [command arguments];
    NSString *contentForPrint = [arguments objectAtIndex:0];
    NSString *chosenPrinterName = [arguments objectAtIndex:1];

    NSString* deviceName = nil;
    NSString* printerName = nil;
    Epos2DeviceInfo* targetPrinter = [NSObject alloc];

    if (targetPrinter != nil) {
        deviceName = [targetPrinter deviceName];
        printerName = [targetPrinter printerName];
    }

    if (deviceName == nil || printerName == nil) {
        [self sendError:@"printer is unavalibale" command:command];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                         messageAsString:@"success"];

        [self.commandDelegate sendPluginResult:pluginResult
                              callbackId:command.callbackId];
    }

    //Create a print document
    int errorStatus = EPOS2_SUCCESS;
    errorStatus = [printer_ addTextLang: EPOS2_LANG_EN];
    errorStatus = [printer_ addTextSmooth: EPOS2_TRUE];
    errorStatus = [printer_ addTextFont: EPOS2_FONT_A];
    errorStatus = [printer_ addTextSize: 3 Height: 3];
    errorStatus = [printer_ addText: contentForPrint];
    errorStatus = [printer_ addCut: EPOS2_CUT_FEED];

    //Initialize an Epos2Printer class instance
    Epos2Printer printer = [[Epos2Printer alloc] initWithPrinterSeries:EPOS2_TM_T88 lang:EPOS2_MODEL_ANK];
    unsigned long status;

    //Send a print document
    if (printer == nil) {
        [self sendError:@"printer initialize error" command:command];
    }

    //<Start communication with the printer>

    errorStatus = [printer connect:deviceName
                           timeout:EPOS2_PARAM_DEFAULT];

    //<Send data>
    errorStatus = [printer_ sendData:builder Timeout:10000 Status:&status];

    [self sendError:errorStatus textForShow:@"Failure to send data to printer" command:command];

    //<Delete the command buffers>
    if ((status & EPOS2_ST_PRINT_SUCCESS) == EPOS2_ST_PRINT_SUCCESS) {
        errorStatus = [builder clearCommandBuffer];
    }

    //<End communication with the printer>
    errorStatus = [printer disconnect];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                     messageAsString:@"success"];

    [self.commandDelegate sendPluginResult:pluginResult
                          callbackId:command.callbackId];

}

- (void) sendError:(int)errorStatus textForShow:(NSString*)text command:(CDVInvokedUrlCommand*)command
{
    if (errorStatus != EPOS2_SUCCESS) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                         messageAsString:[NSString stringWithFormat:@"%@%i", text, errorStatus]];

        [self.commandDelegate sendPluginResult:pluginResult
                              callbackId:command.callbackId];
    }
}

- (void) sendError:(NSString*)text command:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                     messageAsString:text];

    [self.commandDelegate sendPluginResult:pluginResult
                          callbackId:command.callbackId];
}

- (void) onDiscovery:(Epos2DeviceInfo *)deviceInfo {
    NSString* target = [deviceInfo getTarget];
}

@end
