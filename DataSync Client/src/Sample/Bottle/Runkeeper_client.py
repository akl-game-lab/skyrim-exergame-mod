"""An application used to pull data from the HealthGraph-API written in Python using the Bottle
framework. Bottle is a fast, simple and lightweight WSGI micro web-framework for Python.

The configuration file Client_keys.conf must be edited to set the client_id 
and client_secret. The client_id and client_secret is generated upon registration
in the Applications Portal of Health Graph (http://runkeeper.com/partner).

A local server is created on the web browser to the following URL: http://127.0.0.1:8000
"""

from beaker.middleware import SessionMiddleware
from DataSync import DataSyncObject
import os
import sys
import signal
import subprocess
import time
import threading
import bottle
import optparse
import ConfigParser
import HealthGraphPackage

__extension_developers__ = "Rahul Kumar & Jak Tan, 2015"
__original_author__ = "Ali Onur Uyar"
__license__ = "GPL"
__copyright__ = "Copyright 2012, Ali Onur Uyar"
__credits__ = ["Ali Onur Uyar"]

path_to_skyrim = ["C:/Program Files (x86)/Steam/steamapps/common/Skyrim/SkyrimLauncher.exe"]

# Defaults
conf = {'baseurl': 'http://127.0.0.1:8000',
        'bindaddr': '127.0.0.1',
        'bindport': 8000,
        }
defaultConfFilename = 'Client_keys.conf'


# Session Options
sessionOpts = {
    'session.type': 'file',
    'session.cookie_expires': 1800,
    'session.data_dir': '/tmp/cache/data',
    'session.lock_dir': '/tmp/cache/data',
    'session.auto': False,
}


class ConfigurationError(Exception):
    """Base class for Configuration Errors"""
    pass


class terminateThread (threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        time.sleep(2)
        os.kill(signal.CTRL_C_EVENT, 0)


@bottle.route('/')
def index():
    sess = bottle.request.environ['beaker.session']
    if sess.has_key('rk_access_token'):
        bottle.redirect('/welcome')
    else:
        rk_auth_mgr = HealthGraphPackage.AuthManager(conf['client_id'], conf['client_secret'], 
                                          '/'.join((conf['baseurl'], 'login',)))
        rk_auth_uri = rk_auth_mgr.get_login_url()
        rk_button_img = rk_auth_mgr.get_login_button_url('blue', 'black', 300)
        return bottle.template('index.html', {'rk_button_img': rk_button_img,
                                              'rk_auth_uri': rk_auth_uri,})


@bottle.route('/login')
def login():
    sess = bottle.request.environ['beaker.session']
    code = bottle.request.query.get('code')
    if code is not None:
        rk_auth_mgr = HealthGraphPackage.AuthManager(conf['client_id'], conf['client_secret'], 
                                              '/'.join((conf['baseurl'], 'login',)))
        access_token = rk_auth_mgr.get_access_token(code)
        sess['rk_access_token'] = access_token
        sess.save()
        bottle.redirect('/welcome')


@bottle.route('/welcome')
def welcome():
    sess = bottle.request.environ['beaker.session']
    access_token = sess.get('rk_access_token')
    try:
        if access_token is not None:
            user = HealthGraphPackage.User(session=HealthGraphPackage.Session(access_token))
    #         Calls such as user token .get_XXX is where requests occur. If you need to debug a request or add in more request
    #         types (e.g. we extended this project to pull StrengthActivity's as well as FitnessActivity's), look around here.
    #         Use a debugger as it simplifies the request process so much. 
            profile = user.get_profile()
            
            data_sync_obj = DataSyncObject(user)
            data_sync_obj.sync()
            
            return bottle.template('welcome.html', 
                                   profile=profile)
        else:
            bottle.redirect('/')
    except Exception:
        bottle.redirect('/welcome')


@bottle.route('/logout')
def logout():
    sess = bottle.request.environ['beaker.session']
#     Close the session, launch Skyrim and then kill this process
    sess.delete()
    subprocess.call(path_to_skyrim)
    bottle.redirect('/terminate')


@bottle.route('/terminate')
def terminate():
    termThread = terminateThread()
    termThread.start()
    return bottle.template('terminate.html')


def parse_cmdline(argv=None):
    """Parse command line options.
    
    @param argv: List of command line arguments. If None, get list from system.
    @return:     Tuple of Option List and Argument List.
    
    """
    parser = optparse.OptionParser()
    parser.add_option('-c', '--conf', help='Configuration file path.',
                      dest='confpath',default=None)
    parser.add_option('-p', '--bindport',
                      help='Bind to TCP Port. (Default: %d)' % conf['bindport'],
                      dest='bindport', type='int', default=None, action='store')
    parser.add_option('-b', '--bindaddr',
                      help='Bind to IP Address. (Default: %s)' % conf['bindaddr'],
                      dest='bindaddr', default=None, action='store')
    parser.add_option('-u', '--baseurl', 
                      help='Base URL. (Default: %s)' % conf['baseurl'],
                      dest='baseurl', default=None, action='store')
    parser.add_option('-D', '--devel', help='Enable development mode.',
                      dest='devel', default=False, action='store_true')
    if argv is None:
        return parser.parse_args()
    else:
        return parser.parse_args(argv[1:])
    
     
def parse_conf_files(conf_paths):
    """Parse the configuration file and return dictionary of configuration 
    options.
    
    @param conf_paths: List of configuration file paths to parse.
    @return:           Dictionary of configuration options.
    
    """
    conf_file = ConfigParser.RawConfigParser()
    conf_read = conf_file.read(conf_paths)
    conf = {}
    try:
        if conf_read:
            conf['client_id'] = conf_file.get('runkeeper', 'client_id')
            conf['client_secret'] = conf_file.get('runkeeper', 'client_secret')
            if conf_file.has_option('runkeeper', 'bindport'):
                conf['bindport'] = conf_file.getint('runkeeper', 'bindport')
            if conf_file.has_option('runkeeper', 'bindaddr'):
                conf['bindaddr'] = conf_file.get('runkeeper', 'bindaddr')
            if conf_file.has_option('runkeeper', 'baseurl'):
                conf['baseurl'] = conf_file.get('runkeeper', 'baseurl')
            return conf
    except ConfigParser.Error:
        raise ConfigurationError("Error parsing configuration file(s): %s\n" 
                                 % sys.exc_info()[1])
    else:
        raise ConfigurationError("No valid configuration file (%s) found." 
                                 % defaultConfFilename)


def main(argv=None):
    """Main Block - Configure and run the Bottle Web Server."""
    cmd_opts = parse_cmdline(argv)[0]
    if cmd_opts.confpath is not None:
        if os.path.exists(cmd_opts.confpath):
            conf_paths = [cmd_opts.confpath,]
        else:
            return "Configuration file not found: %s" % cmd_opts.confpath
    else:
        conf_paths = [os.path.join(path, defaultConfFilename) 
                      for path in ('/etc', '.',)]
    try:
        conf.update(parse_conf_files(conf_paths))
    except ConfigurationError:
        return(sys.exc_info()[1])
    if cmd_opts.bindport is not None:
        conf['bindport'] = cmd_opts.bindport
    if cmd_opts.bindaddr is not None:
        conf['bindaddr'] = cmd_opts.bindaddr
    if cmd_opts.baseurl is not None:
        conf['baseurl'] = cmd_opts.baseurl
    if cmd_opts.devel:
        from bottle import debug
        debug(True)
    app = SessionMiddleware(bottle.app(), sessionOpts)
    bottle.run(app=app, host=conf['bindaddr'], port=conf['bindport'], 
               reloader=cmd_opts.devel)


if __name__ == "__main__":
    sys.exit(main())