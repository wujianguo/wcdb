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

BindParameter::BindParameter(int n)
{
    syntax.switcher = SyntaxType::Switch::QuestionSign;
    syntax.n = n;
}

BindParameter::BindParameter(const String& name)
{
    syntax.switcher = SyntaxType::Switch::QuestionSign;
    syntax.name = name;
}

BindParameters BindParameter::bindParameters(size_t count)
{
    BindParameters result;
    for (size_t i = 1; i <= count; ++i) {
        result.push_back(BindParameter((int) i));
    }
    return result;
}

BindParameter BindParameter::at(const String& name)
{
    return bindParameter(name, SyntaxType::Switch::AtSign);
}

BindParameter BindParameter::colon(const String& name)
{
    return bindParameter(name, SyntaxType::Switch::ColonSign);
}

BindParameter BindParameter::dollar(const String& name)
{
    return bindParameter(name, SyntaxType::Switch::DollarSign);
}

BindParameter
BindParameter::bindParameter(const String& name, const SyntaxType::Switch& switcher)
{
    BindParameter bindParameter;
    bindParameter.syntax.switcher = switcher;
    bindParameter.syntax.name = name;
    return bindParameter;
}

} // namespace WCDB
