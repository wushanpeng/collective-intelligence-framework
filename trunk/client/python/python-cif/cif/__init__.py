from restclient import GET
import simplejson as json
from texttable import Texttable
import os
import ConfigParser
from base64 import b64decode
import hashlib
import zlib
import pprint
import httplib2
pp = pprint.PrettyPrinter(indent=4)

class Client(object):
    def __init__(self, host, apikey, fields=None, severity=None, restriction=None, nolog=None, confidence=None, simple=None, **args):
        self.host = host
        self.apikey = apikey

        self._fields = fields
        """ override order: passed args, config file args """
        self.severity = severity
        self.restriction = restriction
        self.nolog = nolog
        self.confidence = confidence
        self.simple = simple

    def _get_fields(self):
        return self._fields
        
    def _set_fields(self, fields):
        if fields:
            assert isinstance(fields, list)
        self._fields = fields
    fields = property(_get_fields, _set_fields)
    
    def GET(self,q,severity=None,restriction=None,nolog=None,confidence=None,simple=None):
        s = self.host + '/' + q
        
        params={'apikey':self.apikey}

        if restriction:
            params['restriction'] = restriction
        elif self.restriction:
            params['restriction'] = self.restriction

        if severity:
            params['severity'] = severity
        elif self.severity:
            params['severity'] = self.severity

        if confidence:
            params['confidence'] = confidence
        elif self.confidence:
            params['confidence'] = self.confidence

        if nolog:
            params['nolog'] = 1
        elif self.nolog:
            params['nolog'] = 1

        ret = GET(s, params)
        ret = json.loads(ret)

        """ we're mirroring the perl client lib here """
        self.responseCode = ret['status']

        """ check to see if we've got a feed object, auto-de(code/compress) it """
        feed = ret['data']

        if 'feed' not in feed:
            return

        entry = feed['feed']['entry']
        if isinstance(entry[0],basestring):
            jstring = zlib.decompress(b64decode(entry[0]))
            entry = json.loads(jstring)
            feed['feed']['entry'] = entry

        if simple:
            entries = feed['feed']['entry'] 
            dlist = []
            for incident in entries:
                if(type(incident) == dict):
                    x = self.make_simple(incident['Incident'])
                    dlist.extend([x])
                else:
                    for i in incident:
                        x = self.make_simple(i['Incident'])
                        dlist.extend(x)
            feed['feed']['entry'] = dlist

        return feed

    def make_simple(self,incident):
            ret = {}
            impact = incident['Assessment']['Impact']
            ret['restriction'] = incident['restriction']
            ret['purpose'] = incident['purpose']
            ret['detecttime'] = incident['DetectTime']
            if(incident['IncidentID'].has_key('content')):
                ret['uuid'] = incident['IncidentID']['content']
            ret['source'] = incident['IncidentID']['name']
            ret['description'] = incident['Description']
            ret['confidence'] = incident['Assessment']['Confidence']['content']

            if 'AdditionalData' in incident['EventData']:
                data = incident['EventData']['AdditionalData']
                dlist = [] 
                if(isinstance(data,dict)):
                    dlist.extend([data])
                else:
                    dlist = data

                for d in dlist:
                    if 'meaning' in d:
                        meaning = d['meaning']
                        if meaning in ('malware_md5','malware_sha1','md5','sha1'):
                            ret[meaning] = d['content']

            if 'RelatedActivity' in incident:
                ret['relatedid'] = incident['RelatedActivity']['IncidentID']

            ret['alternativeid'] = None
            ret['alternativeid_restriction'] = None
            if 'AlternativeID' in incident:
                if 'content' in incident['AlternativeID']['IncidentID']:
                    ret['alternativeid'] = incident['AlternativeID']['IncidentID']['content']
                    ret['alternativeid_restriction'] = incident['AlternativeID']['IncidentID']['restriction']

            ret['impact'] = impact
            ret['severity'] = None
            if(isinstance(impact,dict)):
                severity = incident['Assessment']['Impact']['severity']
                impact = impact['content']
                ret['severity'] = severity
                ret['impact'] = impact

            if 'Flow' in incident['EventData']:
                system = incident['EventData']['Flow']['System']
                ret['address'] = system['Node']['Address']
                ret['protocol'] = None
                ret['portlist'] = None
                if(isinstance(ret['address'],dict)):
                    ret['address'] = ret['address']['content']
                if 'Service' in system:
                    ret['protocol'] = system['Service']['ip_protocol']
                    ret['portlist'] = system['Service']['Portlist']

            return ret

    def table(self,feed):
        """
        Take in the JSON object and print a neat table out of the data

        Keyword args:
        self -- self
        feed -- feed dict
        """
        
        j = feed.get('feed')
        created = j.get('detecttime') 
        feedid = j.get('id')
        restriction = j.get('restriction')
        entries = j['entry']
        severity = j.get('severity')
        
        t = Texttable(max_width=0)
        t.set_deco(Texttable.VLINES)

        if self.fields:
            cols = self.fields
        else:
            cols = ['restriction','severity','confidence','detecttime']

            if entries[0].has_key('address'):
                cols.extend(['address','protocol','portlist'])

            for k in 'md5', 'sha1', 'malware_md5', 'malware_sha1':
                if k in entries[0]:
                    cols.append(k)

            cols.extend(['impact','description','alternativeid_restriction','alternativeid'])
        
        t.add_row(cols)
        for item in entries:
            for col in cols:
                if col in item and isinstance(item[col],unicode):
                    item[col] = item[col].encode('utf-8')
                    
            t.add_row([item[col] or '' for col in cols])
            
        table = t.draw()
        
        if created:
            table = 'Feed Created: ' + created + "\n\n" + table

        if restriction:
            table = 'Feed Restriction: ' + restriction + "\n" + table

        if severity:
            table = 'Feed Severity: ' + severity + "\n" + table

        if feedid:
            table = 'Feed Id: ' + feedid + "\n" + table

        return table

class ClientINI(Client):
    def __init__(self, path=None, fields=None, severity=None, restriction=None, nolog=None, confidence=None, simple=None):
        if not path:
            path = os.path.expanduser("~/.cif")
        c = ConfigParser.ConfigParser()
        c.read([path])
        if not c.has_section('client'):
            raise Exception("Unable to read ~/.cif config file")
        vars = dict(c.items("client"))
        if fields:
            vars['fields'] = fields

        Client.__init__(self, **vars)
