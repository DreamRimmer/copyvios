<%include file="/support/header.mako" args="environ=environ, title='Home'"/>
            <div id="content">
% for key, value in environ.items():
                <p><b>${key}</b>: ${value}</p>
% endfor
            </div>
<%include file="/support/footer.mako"/>
