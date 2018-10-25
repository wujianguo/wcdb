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

#include <WCDB/WINQ.h>

namespace WCDB {

StatementReindex& StatementReindex::reindex()
{
    syntax.switcher = SyntaxType::Switch::NotSet;
    return *this;
}

StatementReindex& StatementReindex::collation(const String& collation)
{
    syntax.switcher = SyntaxType::Switch::Collation;
    syntax.collationOrTableOrIndex = collation;
    return *this;
}

StatementReindex& StatementReindex::table(const String& table)
{
    syntax.switcher = SyntaxType::Switch::TableOrIndex;
    syntax.collationOrTableOrIndex = table;
    return *this;
}

StatementReindex& StatementReindex::schema(const Schema& schema)
{
    syntax.schema = schema;
    return *this;
}

StatementReindex& StatementReindex::index(const String& index)
{
    syntax.switcher = SyntaxType::Switch::TableOrIndex;
    syntax.collationOrTableOrIndex = index;
    return *this;
}

} // namespace WCDB
