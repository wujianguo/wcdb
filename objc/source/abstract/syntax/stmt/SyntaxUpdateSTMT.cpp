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

#include <WCDB/Assertion.hpp>
#include <WCDB/Syntax.h>

namespace WCDB {

template<>
constexpr const char* Enum::description(const Syntax::UpdateSTMT::Switch& switcher)
{
    switch (switcher) {
    case Syntax::UpdateSTMT::Switch::Update:
        return "UPDATE";
    case Syntax::UpdateSTMT::Switch::UpdateOrRollback:
        return "UPDATE OR ROLLBACK";
    case Syntax::UpdateSTMT::Switch::UpdateOrAbort:
        return "UPDATE OR ABORT";
    case Syntax::UpdateSTMT::Switch::UpdateOrReplace:
        return "UPDATE OR REPLACE";
    case Syntax::UpdateSTMT::Switch::UpdateOrFail:
        return "UPDATE OR FAIL";
    case Syntax::UpdateSTMT::Switch::UpdateOrIgnore:
        return "UPDATE OR IGNORE";
    }
}

namespace Syntax {

#pragma mark - Identifier
Identifier::Type UpdateSTMT::getType() const
{
    return type;
}

String UpdateSTMT::getDescription() const
{
    std::ostringstream stream;
    if (useWithClause) {
        stream << withClause << space;
    }
    stream << switcher << space << table << " SET ";
    if (!columnsList.empty()) {
        SyntaxRemedialAssert(columnsList.size() == expressions.size());
        auto columns = columnsList.begin();
        auto expression = expressions.begin();
        bool comma = false;
        while (columns != columnsList.end() && expression != expressions.end()) {
            if (comma) {
                stream << ", ";
            } else {
                comma = true;
            }
            if (columns->size() > 1) {
                stream << "(" << *columns << ")";
            } else {
                stream << *columns;
            }
            stream << " = " << *expression;
            ++columns;
            ++expression;
        }
        if (useCondition) {
            stream << " WHERE " << condition;
        }
        if (!orderingTerms.empty()) {
            stream << " ORDER BY " << orderingTerms;
        }
        if (useLimit) {
            stream << " LIMIT " << limit;
            switch (limitParameterType) {
            case LimitParameterType::NotSet:
                break;
            case LimitParameterType::Offset:
                stream << " OFFSET " << limitParameter;
                break;
            case LimitParameterType::End:
                stream << ", " << limitParameter;
                break;
            }
        }
    }
    return stream.str();
}

void UpdateSTMT::iterate(const Iterator& iterator, void* parameter)
{
    Identifier::iterate(iterator, parameter);
    if (useWithClause) {
        withClause.iterate(iterator, parameter);
    }
    table.iterate(iterator, parameter);
    if (!columnsList.empty()) {
        IterateRemedialAssert(columnsList.size() == expressions.size());
        auto columns = columnsList.begin();
        auto expression = expressions.begin();
        while (columns != columnsList.end() && expression != expressions.end()) {
            listIterate(*columns, iterator, parameter);
            expression->iterate(iterator, parameter);
            ++columns;
            ++expression;
        }
        if (useCondition) {
            condition.iterate(iterator, parameter);
        }
        if (!orderingTerms.empty()) {
            listIterate(orderingTerms, iterator, parameter);
        }
        if (useLimit) {
            limit.iterate(iterator, parameter);
            switch (limitParameterType) {
            case LimitParameterType::NotSet:
                break;
            case LimitParameterType::Offset:
            case LimitParameterType::End:
                limitParameter.iterate(iterator, parameter);
                break;
            }
        }
    }
}

} // namespace Syntax

} // namespace WCDB
