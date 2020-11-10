import difflib
import io
import sys
import yaml

# see: https://stackoverflow.com/questions/3790454/how-do-i-break-a-string-over-multiple-lines
# see: https://stackoverflow.com/questions/6432605/any-yaml-libraries-in-python-that-support-dumping-of-long-strings-as-block-liter/20863889
class folded_str(str): pass
class literal_str(str): pass

def change_style(style, representer):
    def new_representer(dumper, data):
        scalar = representer(dumper, data)
        scalar.style = style
        return scalar
    return new_representer

#from yaml.representer import SafeRepresenter
#represent_folded_str = change_style('>', SafeRepresenter.represent_str)
#represent_literal_str = change_style('|', SafeRepresenter.represent_str)
def represent_literal_str(dumper, data):
    return dumper.represent_scalar(u'tag:yaml.org,2002:str', data, style='|')

#yaml.add_representer(folded_str, represent_folded_str)
yaml.add_representer(literal_str, represent_literal_str)

config_orig = open('traefik.yaml', 'r', encoding='utf-8').read()
d = yaml.load(config_orig)

# re-configure traefik to start the api/dashboard.
values = yaml.load(d['spec']['valuesContent'])
values['dashboard'] = {}
values['dashboard']['enabled'] = True
values['dashboard']['domain'] = 'traefik-dashboard.example.com'

# re-configure traefik to skip certificate validation.
# This is needed to expose the k8s dashboard as an ingress at https://kubernetes-dashboard.example.test.
#    TODO see how to set the CAs in traefik.
# This should never be done at production.
values['ssl']['insecureSkipVerify'] = True

# save values back.
config = io.StringIO(newline='\n')
yaml.dump(values, config, default_flow_style=False)
d['spec']['valuesContent'] = literal_str(config.getvalue())

# show the differences and save the modified yaml file.
config = io.StringIO(newline='\n')
yaml.dump(d, config, default_flow_style=False)
config = config.getvalue()
sys.stdout.writelines(difflib.unified_diff(config_orig.splitlines(1), config.splitlines(1)))
open('traefik.yaml', 'w', encoding='utf-8').write(config)
