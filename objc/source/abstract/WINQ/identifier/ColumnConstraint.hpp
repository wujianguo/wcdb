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

#ifndef ColumnConstraint_hpp
#define ColumnConstraint_hpp

#include <WCDB/SQL.hpp>

namespace WCDB {

class ColumnConstraint : public SQLSyntax<Syntax::ColumnConstraint> {
public:
    ColumnConstraint();
    explicit ColumnConstraint(const String& name);

    ColumnConstraint& primaryKey();
    ColumnConstraint& order(const Order& order);
    ColumnConstraint& conflict(const Conflict& conflict);
    ColumnConstraint& autoIncrement();

    ColumnConstraint& notNull();
    ColumnConstraint& unique();

    ColumnConstraint& check(const Expression& expression);

    ColumnConstraint& default_(const LiteralValue& defaultValue);
    ColumnConstraint& default_(const Expression& defaultValue);

    ColumnConstraint& collate(const String& collation);
    ColumnConstraint& foreignKey(const ForeignKey& foreignKey);
};

} // namespace WCDB

#endif /* ColumnConstraint_hpp */
