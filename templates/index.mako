<%! from flask import g, request %>\
<%include file="/support/header.mako" args="title='Earwig\'s Copyvio Detector'"/>
<%namespace module="copyvios.highlighter" import="highlight_delta"/>\
<%namespace module="copyvios.misc" import="urlstrip"/>\
% if query.project and query.lang and (query.title or query.oldid):
    % if query.error == "bad URI":
        <div id="info-box" class="red-box">
            <p>Unsupported URI scheme: <a href="${query.url | h}">${query.url | h}</a>.</p>
        </div>
    % elif not query.site:
        <div id="info-box" class="red-box">
            <p>The given site (project=<b><span class="mono">${query.project | h}</span></b>, language=<b><span class="mono">${query.lang | h}</span></b>) doesn't seem to exist. It may also be closed or private. <a href="//${query.lang | h}.${query.project | h}.org/">Confirm its URL.</a></p>
        </div>
    % elif query.title and not result:
        <div id="info-box" class="red-box">
            <p>The given page doesn't seem to exist: <a href="${query.page.url}">${query.page.title | h}</a>.</p>
        </div>
    % elif query.oldid and not result:
        <div id="info-box" class="red-box">
            <p>The given revision ID doesn't seem to exist: <a href="//${query.site.domain | h}/w/index.php?oldid=${query.oldid | h}">${query.oldid | h}</a>.</p>
        </div>
    % endif
%endif
<p>This tool attempts to detect <a href="//en.wikipedia.org/wiki/WP:COPYVIO">copyright violations</a> in articles. Simply give the title of the page or ID of the revision you want to check and hit Submit. The tool will search for similar content elsewhere on the web using <a href="//info.yahoo.com/legal/us/yahoo/boss/pricing/">Yahoo! BOSS</a> and then display a report if a match is found. If you give a URL, it will skip the search engine step and directly display a report comparing the article to that particular webpage, like the <a href="//toolserver.org/~dcoetzee/duplicationdetector/">Duplication Detector</a>.</p>
<p>Specific websites can be excluded from the check (for example, if their content is in the public domain) by being added to the <a href="//en.wikipedia.org/wiki/User:EarwigBot/Copyvios/Exclusions">excluded URL list</a>.</p>
<p><i>Note:</i> The tool is still in beta. You are completely welcome to use it and provide <a href="//en.wikipedia.org/wiki/User_talk:The_Earwig">feedback</a>, but be aware that it may produce strange or broken results.</p>
<form action="${request.base_url}" method="get">
    <table id="cv-form">
        <tr>
            <td>Site:</td>
            <td colspan="3">
                <span class="mono">http://</span>
                <select name="lang">
                    <% selected_lang = query.orig_lang if query.orig_lang else g.cookies["CopyviosDefaultLang"].value if "CopyviosDefaultLang" in g.cookies else query.bot.wiki.get_site().lang %>\
                    % for code, name in query.all_langs:
                        % if code == selected_lang:
                            <option value="${code | h}" selected="selected">${name}</option>
                        % else:
                            <option value="${code | h}">${name}</option>
                        % endif
                    % endfor
                </select>
                <span class="mono">.</span>
                <select name="project">
                    <% selected_project = query.project if query.project else g.cookies["CopyviosDefaultProject"].value if "CopyviosDefaultProject" in g.cookies else query.bot.wiki.get_site().project %>\
                    % for code, name in query.all_projects:
                        % if code == selected_project:
                            <option value="${code | h}" selected="selected">${name}</option>
                        % else:
                            <option value="${code | h}">${name}</option>
                        % endif
                    % endfor
                </select>
                <span class="mono">.org</span>
            </td>
        </tr>
        <tr>
            <td id="cv-col1">Page&nbsp;title:</td>
            <td id="cv-col2">
                % if query.page:
                    <input class="cv-text" type="text" name="title" value="${query.page.title | h}" />
                % elif query.title:
                    <input class="cv-text" type="text" name="title" value="${query.title | h}" />
                % else:
                    <input class="cv-text" type="text" name="title" />
                % endif
            </td>
            <td id="cv-col3">or&nbsp;revision&nbsp;ID:</td>
            <td id="cv-col4">
                % if query.oldid:
                    <input class="cv-text" type="text" name="oldid" value="${query.oldid | h}" />
                % else:
                    <input class="cv-text" type="text" name="oldid" />
                % endif
            </td>
        </tr>
        <tr>
            <td>URL&nbsp;(optional):</td>
            <td colspan="3">
                % if query.url:
                    <input class="cv-text" type="text" name="url" value="${query.url | h}" />
                % else:
                    <input class="cv-text" type="text" name="url" />
                % endif
            </td>
        </tr>
        % if query.nocache or (result and result.cached):
            <tr>
                <td>Bypass&nbsp;cache:</td>
                <td colspan="3">
                    % if query.nocache:
                        <input type="checkbox" name="nocache" value="1" checked="checked" />
                    % else:
                        <input type="checkbox" name="nocache" value="1" />
                    % endif
                </td>
            </tr>
        % endif
        <tr>
            <td colspan="4">
                <button type="submit">Submit</button>
            </td>
        </tr>
    </table>
</form>
% if result:
    <% show_details = "CopyviosShowDetails" in g.cookies and g.cookies["CopyviosShowDetails"].value == "True" %>
    <div class="divider"></div>
    <div id="cv-result" class="${'red' if result.violation else 'green'}-box">
        % if result.violation:
            <h2 id="cv-result-header"><a href="${query.page.url}">${query.page.title | h}</a> is a suspected violation of <a href="${result.url | h}">${result.url | urlstrip, h}</a>.</h2>
        % else:
            <h2 id="cv-result-header">No violations detected in <a href="${query.page.url}">${query.page.title | h}</a>.</h2>
        % endif
        <ul id="cv-result-list">
            % if not result.violation and not query.url:
                % if result.url:
                    <li>Best match: <a href="${result.url | h}">${result.url | urlstrip, h}</a>.</li>
                % else:
                    <li>No matches found.</li>
                % endif
            % endif
            <li><b><span class="mono">${round(result.confidence * 100, 1)}%</span></b> confidence of a violation.</li>
            % if result.cached:
                <li>Results are <a id="cv-cached" href="#">cached
                    <span>To save time (and money), this tool will retain the results of checks for up to 72 hours. This includes the URL of the "violated" source, but neither its content nor the content of the article. Future checks on the same page (assuming it remains unchanged) will not involve additional search queries, but a fresh comparison against the source URL will be made. If the page is modified, a new check will be run.</span>
                </a> from ${result.cache_time} (${result.cache_age} ago). <a href="${request.url | h}&amp;nocache=1">Bypass the cache.</a></li>
            % else:
                <li>Results generated in <span class="mono">${round(result.time, 3)}</span> seconds using <span class="mono">${result.queries}</span> queries.</li>
            % endif
            <li><a id="cv-result-detail-link" href="#cv-result-detail" onclick="copyvio_toggle_details()">${"Hide" if show_details else "Show"} details:</a></li>
        </ul>
        <div id="cv-result-detail" style="display: ${'block' if show_details else 'none'};">
            <ul id="cv-result-detail-list">
                <li>Trigrams: <i>Article:</i> <span class="mono">${result.article_chain.size()}</span> / <i>Source:</i> <span class="mono">${result.source_chain.size()}</span> / <i>Delta:</i> <span class="mono">${result.delta_chain.size()}</span></li>
                % if result.cached:
                    % if result.queries:
                        <li>Retrieved from cache in <span class="mono">${round(result.time, 3)}</span> seconds (originally generated in <span class="mono">${round(result.original_time, 3)}</span>s using <span class="mono">${result.queries}</span> queries; <span class="mono">${round(result.original_time - result.time, 3)}</span>s saved).</li>
                    % else:
                        <li>Retrieved from cache in <span class="mono">${round(result.time, 3)}</span> seconds (originally generated in <span class="mono">${round(result.original_time, 3)}</span>s; <span class="mono">${round(result.original_time - result.time, 3)}</span>s saved).</li>
                    % endif
                % endif
                % if result.queries:
                    <li><i>Fun fact:</i> The Wikimedia Foundation paid Yahoo! Inc. <a href="http://info.yahoo.com/legal/us/yahoo/search/bosspricing/details.html">$${result.queries * 0.0008} USD</a> for these results.</li>
                % endif
            </ul>
            <table id="cv-chain-table">
                <tr>
                    <td class="cv-chain-cell">Article: <div class="cv-chain-detail"><p>${highlight_delta(result.article_chain, result.delta_chain)}</p></div></td>
                    <td class="cv-chain-cell">Source: <div class="cv-chain-detail"><p>${highlight_delta(result.source_chain, result.delta_chain)}</p></div></td>
                </tr>
            </table>
        </div>
    </div>
% endif
<%include file="/support/footer.mako"/>
