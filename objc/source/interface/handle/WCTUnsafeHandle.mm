/*
 * Tencent is pleased to support the open source community by making
 * WCDB available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company.
 * All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use
 * this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *       https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <WCDB/Assertion.hpp>
#import <WCDB/Interface.h>
#import <WCDB/Notifier.hpp>
#import <WCDB/WCTCore+Private.h>
#import <WCDB/WCTError+Private.h>
#import <WCDB/WCTUnsafeHandle+Private.h>
#import <WCDB/WCTValue+Private.h>

@implementation WCTUnsafeHandle

#pragma mark - Initialize
- (instancetype)initWithCore:(WCTCore *)core
{
    if (self = [super initWithCore:core]) {
        _finalizeLevel = WCTFinalizeLevelDatabase;
    }
    return self;
}

- (instancetype)initWithCore:(WCTCore *)core
         andRecyclableHandle:(const WCDB::RecyclableHandle &)recyclableHandle
{
    WCTInnerAssert(recyclableHandle != nullptr);
    if (self = [super initWithCore:core]) {
        _recyclableHandle = recyclableHandle;
        _handle = recyclableHandle.get();
    }
    return self;
}

- (instancetype)initWithCore:(WCTCore *)core
                   andHandle:(WCDB::Handle *)handle
{
    //Unsafe
    WCTInnerAssert(handle != nullptr);
    if (self = [super initWithCore:core]) {
        _handle = handle;
    }
    return self;
}

- (void)dealloc
{
    [self finalizeHandle];
}

#pragma mark - Safety

- (BOOL)isSafe
{
    //It's safe if it will or did capture a recyclable one
    return _recyclableHandle != nullptr || _handle == nullptr;
}

- (void)generateIfNeeded
{
    if (_handle == nullptr) {
        _recyclableHandle = _database->getHandle();
        if (_recyclableHandle != nullptr) {
            _handle = _recyclableHandle.get();
        } else {
            _nonHandleError = [[WCTError alloc] initWithError:_database->getThreadedError()];
        }
    }
}

- (WCDB::Handle *)getOrGenerateHandle
{
    [self generateIfNeeded];
    return _handle;
}

- (void)finalizeHandleIfGeneratedAndKeepError:(BOOL)keepError
{
    if (_handle) {
        _handle->finalize();
        if (keepError && _handle->getResultCode() != 0) {
            _nonHandleError = [[WCTError alloc] initWithError:_handle->getError()];
        } else {
            _nonHandleError = nil;
        }
    } else {
        _nonHandleError = nil;
    }
    _recyclableHandle = nullptr;
    _handle = nullptr;
}

#pragma mark - Life Cycle

- (void)finalizeStatement
{
    if (_handle) {
        _handle->finalize();
    }
}

- (void)finalizeHandle
{
    [self finalizeHandleIfGeneratedAndKeepError:NO];
}

#pragma mark - Bind row
- (void)bindProperty:(const WCTProperty &)property
            ofObject:(WCTObject *)object
             toIndex:(int)index
{
    WCTHandleAssert(return;);
    const WCTColumnBinding &columnBinding = property.getColumnBinding();
    const std::shared_ptr<WCTBaseAccessor> &accessor = columnBinding.accessor;
    switch (accessor->getAccessorType()) {
    case WCTAccessorCpp: {
        switch (accessor->getColumnType()) {
        case WCDB::ColumnType::Integer32: {
            WCTCppAccessor<WCDB::ColumnType::Integer32> *i32Accessor = (WCTCppAccessor<WCDB::ColumnType::Integer32> *) accessor.get();
            _handle->bindInteger32(i32Accessor->getValue(object),
                                   index);
        } break;
        case WCDB::ColumnType::Integer64: {
            WCTCppAccessor<WCDB::ColumnType::Integer64> *i64Accessor = (WCTCppAccessor<WCDB::ColumnType::Integer64> *) accessor.get();
            _handle->bindInteger64(i64Accessor->getValue(object),
                                   index);
        } break;
        case WCDB::ColumnType::Float: {
            WCTCppAccessor<WCDB::ColumnType::Float> *floatAccessor = (WCTCppAccessor<WCDB::ColumnType::Float> *) accessor.get();
            _handle->bindDouble(floatAccessor->getValue(object),
                                index);
        } break;
        case WCDB::ColumnType::Text: {
            WCTCppAccessor<WCDB::ColumnType::Text> *textAccessor = (WCTCppAccessor<WCDB::ColumnType::Text> *) accessor.get();
            _handle->bindText(textAccessor->getValue(object),
                              index);
        } break;
        case WCDB::ColumnType::BLOB: {
            WCTCppAccessor<WCDB::ColumnType::BLOB> *blobAccessor = (WCTCppAccessor<WCDB::ColumnType::BLOB> *) accessor.get();
            _handle->bindBLOB(blobAccessor->getValue(object), index);
        } break;
        case WCDB::ColumnType::Null:
            _handle->bindNull(index);
            break;
        }
    } break;
    case WCTAccessorObjC: {
        WCTObjCAccessor *objcAccessor = (WCTObjCAccessor *) accessor.get();
        NSObject *value = objcAccessor->getObject(object);
        if (value) {
            switch (accessor->getColumnType()) {
            case WCDB::ColumnType::Integer32: {
                NSNumber *number = (NSNumber *) value;
                _handle->bindInteger32(number.intValue, index);
                break;
            }
            case WCDB::ColumnType::Integer64: {
                NSNumber *number = (NSNumber *) value;
                _handle->bindInteger64(number.longLongValue, index);
                break;
            }
            case WCDB::ColumnType::Float: {
                NSNumber *number = (NSNumber *) value;
                _handle->bindDouble(number.numberValue.doubleValue, index);
                break;
            }
            case WCDB::ColumnType::Text: {
                NSString *string = (NSString *) value;
                _handle->bindText(string.UTF8String, index);
                break;
            }
            case WCDB::ColumnType::BLOB: {
                NSData *data = (NSData *) value;
                _handle->bindBLOB(WCDB::UnsafeData::immutable((const unsigned char *) data.bytes, (size_t) data.length), index);
                break;
            }
            case WCDB::ColumnType::Null:
                _handle->bindNull(index);
                break;
            }
        } else {
            _handle->bindNull(index);
        }
    } break;
    }
}

- (void)bindProperties:(const WCTProperties &)properties
              ofObject:(WCTObject *)object
{
    int i = 0;
    for (const WCTProperty &property : properties) {
        ++i;
        [self bindProperty:property
                  ofObject:object
                   toIndex:i];
    }
}

- (void)bindValue:(WCTColumnCodingValue *)value
          toIndex:(int)index
{
    WCTHandleAssert(return;);
    value = [value archivedWCTValue];
    if ([value isKindOfClass:NSData.class]) {
        NSData *data = (NSData *) value;
        _handle->bindBLOB(WCDB::UnsafeData::immutable((const unsigned char *) data.bytes, (size_t) data.length), index);
    } else if ([value isKindOfClass:NSString.class]) {
        NSString *string = (NSString *) value;
        _handle->bindText(string.UTF8String, index);
    } else if ([value isKindOfClass:NSNumber.class]) {
        NSNumber *number = (NSNumber *) value;
        if (CFNumberIsFloatType((CFNumberRef) number)) {
            _handle->bindDouble(number.numberValue.doubleValue, index);
        } else {
            if (CFNumberGetByteSize((CFNumberRef) number) <= 4) {
                _handle->bindInteger32(number.intValue, index);
            } else {
                _handle->bindInteger64(number.longLongValue, index);
            }
        }
    } else {
        _handle->bindNull(index);
    }
}

#pragma mark - Get row
- (void)extractValueAtIndex:(int)index
                 toProperty:(const WCTProperty &)property
                   ofObject:(WCTObject *)object
{
    WCTHandleAssert(return;);
    const WCTColumnBinding &columnBinding = property.getColumnBinding();
    const std::shared_ptr<WCTBaseAccessor> &accessor = columnBinding.accessor;
    switch (accessor->getAccessorType()) {
    case WCTAccessorCpp: {
        switch (accessor->getColumnType()) {
        case WCDB::ColumnType::Integer32: {
            WCTCppAccessor<WCDB::ColumnType::Integer32> *i32Accessor = (WCTCppAccessor<WCDB::ColumnType::Integer32> *) accessor.get();
            i32Accessor->setValue(object, _handle->getInteger32(index));
        } break;
        case WCDB::ColumnType::Integer64: {
            WCTCppAccessor<WCDB::ColumnType::Integer64> *i64Accessor = (WCTCppAccessor<WCDB::ColumnType::Integer64> *) accessor.get();
            i64Accessor->setValue(object, _handle->getInteger64(index));
        } break;
        case WCDB::ColumnType::Float: {
            WCTCppAccessor<WCDB::ColumnType::Float> *floatAccessor = (WCTCppAccessor<WCDB::ColumnType::Float> *) accessor.get();
            floatAccessor->setValue(object, _handle->getDouble(index));
        } break;
        case WCDB::ColumnType::Text: {
            WCTCppAccessor<WCDB::ColumnType::Text> *textAccessor = (WCTCppAccessor<WCDB::ColumnType::Text> *) accessor.get();
            textAccessor->setValue(object, _handle->getText(index));
        } break;
        case WCDB::ColumnType::BLOB: {
            WCTCppAccessor<WCDB::ColumnType::BLOB> *blobAccessor = (WCTCppAccessor<WCDB::ColumnType::BLOB> *) accessor.get();
            blobAccessor->setValue(object, _handle->getBLOB(index));
        } break;
        case WCDB::ColumnType::Null: {
            WCTCppAccessor<WCDB::ColumnType::Null> *nullAccessor = (WCTCppAccessor<WCDB::ColumnType::Null> *) accessor.get();
            nullAccessor->setValue(object, nullptr);
        } break;
        }
    } break;
    case WCTAccessorObjC: {
        WCTObjCAccessor *objcAccessor = (WCTObjCAccessor *) accessor.get();
        id value = nil;
        if (_handle->getType(index) != WCDB::ColumnType::Null) {
            switch (accessor->getColumnType()) {
            case WCDB::ColumnType::Integer32:
                value = [NSNumber numberWithInt:_handle->getInteger32(index)];
                break;
            case WCDB::ColumnType::Integer64:
                value = [NSNumber numberWithLongLong:_handle->getInteger64(index)];
                break;
            case WCDB::ColumnType::Float:
                value = [NSNumber numberWithDouble:_handle->getDouble(index)];
                break;
            case WCDB::ColumnType::Text:
                value = [NSString stringWithUTF8String:_handle->getText(index)];
                break;
            case WCDB::ColumnType::BLOB: {
                const WCDB::UnsafeData data = _handle->getBLOB(index);
                value = [NSData dataWithBytes:data.buffer() length:data.size()];
            } break;
            case WCDB::ColumnType::Null:
                value = nil;
                break;
            }
        }
        objcAccessor->setObject(object, value);
    } break;
    }
}

- (WCTValue *)getValueAtIndex:(int)index
{
    WCTHandleAssert(return nil;);
    switch (_handle->getType(index)) {
    case WCDB::ColumnType::Integer32:
        return [NSNumber numberWithInt:_handle->getInteger32(index)];
    case WCDB::ColumnType::Integer64:
        return [NSNumber numberWithLongLong:_handle->getInteger64(index)];
    case WCDB::ColumnType::Float:
        return [NSNumber numberWithDouble:_handle->getDouble(index)];
    case WCDB::ColumnType::Text:
        return [NSString stringWithUTF8String:_handle->getText(index)];
    case WCDB::ColumnType::BLOB: {
        const WCDB::UnsafeData data = _handle->getBLOB(index);
        return [NSData dataWithBytes:data.buffer() length:data.size()];
    }
    case WCDB::ColumnType::Null:
        return nil;
    }
}

- (WCTOneRow *)getRow
{
    WCTHandleAssert(return nil;);
    NSMutableArray<WCTValue *> *row = [[NSMutableArray<WCTValue *> alloc] init];
    for (int i = 0; i < _handle->getColumnCount(); ++i) {
        WCTValue *value = [self getValueAtIndex:i];
        [row addObject:value ? value : [NSNull null]];
    }
    return row;
}

- (WCTObject *)getObjectOfClass:(Class)cls onProperties:(const WCTProperties &)properties
{
    WCTObject *object = [[cls alloc] init];
    if (!object) {
        return nil;
    }
    int index = 0;
    for (const WCTProperty &property : properties) {
        [self extractValueAtIndex:index
                       toProperty:property
                         ofObject:object];
        ++index;
    };
    return object;
}

#pragma mark - Error

- (WCTError *)error
{
    if (_handle) {
        return [[WCTError alloc] initWithError:_handle->getError()];
    }
    return _nonHandleError;
}

#pragma mark - Convenient
- (BOOL)execute:(const WCDB::Statement &)statement
{
    WCDB::Handle *handle = [self getOrGenerateHandle];
    if (!handle) {
        return NO;
    }
    return handle->execute(statement);
}

- (BOOL)prepare:(const WCDB::Statement &)statement
{
    WCDB::Handle *handle = [self getOrGenerateHandle];
    if (!handle) {
        return NO;
    }
    return handle->prepare(statement);
}

- (WCTValue *)nextValueAtIndex:(int)index orDone:(BOOL &)isDone
{
    WCTHandleAssert(return nil;);
    if (_handle->step((bool &) isDone) && !isDone) {
        return [self getValueAtIndex:index];
    }
    [self finalizeStatement];
    return nil;
}

- (WCTOneColumn *)allValuesAtIndex:(int)index
{
    WCTHandleAssert(return nil;);
    NSMutableArray<WCTValue *> *values = [[NSMutableArray<WCTValue *> alloc] init];
    bool done = false;
    while (_handle->step(done) && !done) {
        WCTValue *value = [self getValueAtIndex:index];
        [values addObject:value ? value : [NSNull null]];
    }
    [self finalizeStatement];
    return done ? values : nil;
}

- (WCTOneRow *)nextRowOrDone:(BOOL &)isDone
{
    WCTHandleAssert(return nil;);
    if (_handle->step((bool &) isDone) && !isDone) {
        return [self getRow];
    }
    [self finalizeStatement];
    return nil;
}

- (WCTColumnsXRows *)allRows
{
    WCTHandleAssert(return nil;);
    NSMutableArray<WCTOneRow *> *rows = [[NSMutableArray<WCTOneRow *> alloc] init];
    bool done = false;
    while (_handle->step(done) && !done) {
        [rows addObject:[self getRow]];
    }
    [self finalizeStatement];
    return done ? rows : nil;
}

- (id /* WCTObject* */)nextObjectOnResultColumns:(const WCDB::ResultColumns &)resultColumns orDone:(BOOL &)isDone
{
    if (resultColumns.empty()) {
        return nil;
    }
#warning TODO
    //    Class cls = resultColumns.front().getColumnBinding().getClass();
    //    if (_handle->step((bool &) isDone) && !isDone) {
    //                return [self getObjectOfClass:cls onResultColumns:resultColumns];
    //    }
    //    [self finalizeStatement];
    return nil;
}

- (NSArray /* <WCTObject*> */ *)allObjectsOnResultColumns:(const WCDB::ResultColumns &)resultColumns
{
    if (resultColumns.empty()) {
        return nil;
    }
#warning TODO
    //    Class cls = resultColumns.front().getColumnBinding().getClass();
    //    WCTHandleAssert(return nil;);
    //    NSMutableArray<WCTObject *> *objects = [[NSMutableArray<WCTObject *> alloc] init];
    //    bool done = false;
    //    while (_handle->step(done) && !done) {
    //                [objects addObject:[self getObjectOfClass:cls OnResultColumns:resultColumns]];
    //    }
    //    [self finalizeStatement];
    //    return done ? objects : nil;
    return nil;
}

- (BOOL)execute:(const WCDB::Statement &)statement
     withObject:(WCTObject *)object
{
    Class cls = object.class;
    const WCTProperties &properties = [cls allProperties];
    return [self execute:statement
              withObject:object
            onProperties:properties];
}

- (BOOL)execute:(const WCDB::Statement &)statement
     withObject:(WCTObject *)object
   onProperties:(const WCTProperties &)properties
{
    if (![self prepare:statement]) {
        return NO;
    }
    [self bindProperties:properties ofObject:object];
    BOOL result = _handle->step();
    [self finalizeStatement];
    return result;
}

- (BOOL)execute:(const WCDB::Statement &)statement
      withValue:(WCTColumnCodingValue *)value
{
    if (![self prepare:statement]) {
        return NO;
    }
    [self bindValue:value toIndex:1];
    BOOL result = _handle->step();
    [self finalizeStatement];
    return result;
}

- (BOOL)execute:(const WCDB::Statement &)statement
        withRow:(WCTOneRow *)row
{
    if (![self prepare:statement]) {
        return NO;
    }
    int index = 1;
    for (WCTColumnCodingValue *value in row) {
        [self bindValue:value toIndex:index];
        ++index;
    }
    BOOL result = _handle->step();
    [self finalizeStatement];
    return result;
}

- (BOOL)rebindTable:(NSString *)tableName toClass:(Class<WCTTableCoding>)cls
{
    WCTInnerAssert(tableName && cls);
    WCDB::Handle *handle = [self getOrGenerateHandle];
    if (!handle) {
        return NO;
    }
    WCDB::String table = tableName.cppString;
    const WCTBinding &binding = [cls objectRelationalMapping];
    std::pair<bool, bool> tableExists = handle->tableExists(table);
    if (!tableExists.first) {
        return NO;
    }
    if (tableExists.second) {
        auto pair = handle->getUnorderedColumnsWithTable(table);
        if (!pair.first) {
            return NO;
        }
        std::set<WCDB::String> &columnNames = pair.second;
        std::list<const WCTColumnBinding *> columnBindingsToAdded;
        //Check whether the column names exists
        const auto &columnBindings = binding.getColumnBindings();
        for (const auto &columnBinding : columnBindings) {
            auto iter = columnNames.find(columnBinding.first);
            if (iter == columnNames.end()) {
                columnBindingsToAdded.push_back(&columnBinding.second);
            } else {
                columnNames.erase(iter);
            }
        }
        for (const WCDB::String &columnName : columnNames) {
            WCDB::Error error;
            error.setCode(WCDB::Error::Code::Mismatch);
            error.level = WCDB::Error::Level::Notice;
            error.message = "Skip column";
            error.infos.set("Table", tableName.cppString);
            error.infos.set("Column", columnName);
            error.infos.set("Path", self.path.cppString);
            WCDB::Notifier::shared()->notify(error);
        }
        //Add new column
        for (const WCTColumnBinding *columnBinding : columnBindingsToAdded) {
            if (!handle->execute(WCDB::StatementAlterTable().alterTable(table).addColumn(columnBinding->columnDef))) {
                return NO;
            }
        }
    } else {
        if (!handle->execute(binding.generateCreateTableStatement(tableName.cppString))) {
            return NO;
        }
    }
    for (const WCDB::StatementCreateIndex &statementCreateIndex : binding.generateCreateIndexStatements(table)) {
        if (!handle->execute(statementCreateIndex)) {
            return NO;
        }
    }
    return YES;
}

- (void)finalizeDatabase
{
    [self finalizeDatabase:NO];
}

- (instancetype)autoFinalizeStatement
{
    _finalizeLevel = WCTFinalizeLevelStatement;
    return self;
}

- (instancetype)autoFinalizeHandle
{
    _finalizeLevel = WCTFinalizeLevelHandle;
    return self;
}

- (instancetype)autoFinalizeDatabase
{
    _finalizeLevel = WCTFinalizeLevelDatabase;
    return self;
}

- (void)finalizeDatabase:(BOOL)keepError
{
    [self finalizeHandleIfGeneratedAndKeepError:keepError];
    [super finalizeDatabase];
}

- (void)doAutoFinalize:(BOOL)keepError
{
    switch (_finalizeLevel) {
    case WCTFinalizeLevelHandle:
        [self finalizeHandleIfGeneratedAndKeepError:keepError];
        break;
    case WCTFinalizeLevelStatement:
        [self finalizeStatement];
        break;
    case WCTFinalizeLevelDatabase:
        [self finalizeDatabase:keepError];
        break;
    default:
        break;
    }
}

@end
