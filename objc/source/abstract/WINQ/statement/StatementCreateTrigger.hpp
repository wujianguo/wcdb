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

#ifndef StatementCreateTrigger_hpp
#define StatementCreateTrigger_hpp

#include <WCDB/Statement.hpp>

namespace WCDB {

class StatementCreateTrigger : public StatementSyntax<Syntax::CreateTriggerSTMT> {
public:
    StatementCreateTrigger& createTrigger(const String& trigger);
    StatementCreateTrigger& schema(const Schema& schema);
    StatementCreateTrigger& temp();
    StatementCreateTrigger& ifNotExists();

    StatementCreateTrigger& before();
    StatementCreateTrigger& after();
    StatementCreateTrigger& insteadOf();

    StatementCreateTrigger& delete_();
    StatementCreateTrigger& insert();
    StatementCreateTrigger& update();
    StatementCreateTrigger& updateOf(const Columns& columns);

    StatementCreateTrigger& on(const String& table);

    StatementCreateTrigger& forEachRow();

    StatementCreateTrigger& when(const Expression& condition);

    StatementCreateTrigger& execute(const StatementInsert& statement);
    StatementCreateTrigger& execute(const StatementUpdate& statement);
    StatementCreateTrigger& execute(const StatementDelete& statement);
    StatementCreateTrigger& execute(const StatementSelect& statement);
};

} // namespace WCDB

#endif /* StatementCreateTrigger_hpp */
