//
//  CBPeripheral+RZBExtension.m
//  UMTSDK
//
//  Created by Brian King on 7/30/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "CBPeripheral+RZBExtension.h"
#import "CBPeripheral+RZBHelper.h"
#import "CBCharacteristic+RZBExtension.h"
#import "CBService+RZBExtension.h"
#import "RZBCentralManager+Private.h"
#import "RZBUUIDPath.h"
#import "RZBCommand.h"

@implementation CBPeripheral (RZBExtension)

- (RZBCommandDispatch *)dispatch
{
    return self.rzb_centralManager.dispatch;
}

- (void)rzb_readCharacteristicUUID:(CBUUID *)characteristicUUID
                       serviceUUID:(CBUUID *)serviceUUID
                        completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBReadCharacteristicCommand *cmd = [[RZBReadCharacteristicCommand alloc] initWithUUIDPath:path];
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

- (void)rzb_addObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                 serviceUUID:(CBUUID *)serviceUUID
                                    onChange:(RZBCharacteristicBlock)onChange
                                  completion:(RZBCharacteristicBlock)completion;
{
    NSParameterAssert(onChange);
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = YES;
    [cmd addCallbackBlock:^(CBCharacteristic *characteristic, NSError *error) {
        characteristic.rzb_notificationBlock = onChange;
        completion(characteristic, error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)rzb_removeObserverForCharacteristicUUID:(CBUUID *)characteristicUUID
                                    serviceUUID:(CBUUID *)serviceUUID
                                     completion:(RZBCharacteristicBlock)completion;
{
    NSParameterAssert(completion);

    // Remove the completion block immediately to behave consistently.
    // If anything here is nil, there is no completion block, which is fine.
    CBService *service = [self.rzb_centralManager serviceForUUID:serviceUUID onPeripheral:self];
    CBCharacteristic *characteristic = [service rzb_characteristicForUUID:characteristicUUID];
    characteristic.rzb_notificationBlock = nil;

    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBNotifyCharacteristicCommand *cmd = [[RZBNotifyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.notify = NO;
    [cmd addCallbackBlock:^(CBCharacteristic *c, NSError *error) {
        completion(c, error);
    }];
    [self.dispatch dispatchCommand:cmd];
}

- (void)rzb_writeData:(NSData *)data
   characteristicUUID:(CBUUID *)characteristicUUID
          serviceUUID:(CBUUID *)serviceUUID
{
    NSParameterAssert(data);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBWriteCharacteristicCommand *cmd = [[RZBWriteCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.data = data;
    [self.dispatch dispatchCommand:cmd];
}

- (void)rzb_writeData:(NSData *)data
   characteristicUUID:(CBUUID *)characteristicUUID
          serviceUUID:(CBUUID *)serviceUUID
           completion:(RZBCharacteristicBlock)completion
{
    NSParameterAssert(data);
    NSParameterAssert(completion);
    RZBUUIDPath *path = RZBUUIDP(self.identifier, serviceUUID, characteristicUUID);
    RZBWriteCharacteristicCommand *cmd = [[RZBWriteWithReplyCharacteristicCommand alloc] initWithUUIDPath:path];
    cmd.data = data;
    [cmd addCallbackBlock:completion];
    [self.dispatch dispatchCommand:cmd];
}

@end
