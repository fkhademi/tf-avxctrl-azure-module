import subprocess
import json

process = subprocess.Popen(['az','vm', 'image', 'terms', 'show', '--urn', 'aviatrix-systems:aviatrix-bundle-payg:aviatrix-enterprise-bundle-byol:latest'], stdout=subprocess.PIPE)
out, err = process.communicate()
d = json.loads(out)
if d['accepted'] == False:
    process = subprocess.Popen(['az','vm', 'image', 'terms', 'accept', '--urn', 'aviatrix-systems:aviatrix-bundle-payg:aviatrix-enterprise-bundle-byol:latest'], stdout=subprocess.PIPE)

processCopilot = subprocess.Popen(['az','vm', 'image', 'terms', 'show', '--urn', 'aviatrix-systems:aviatrix-copilot:avx-cplt-byol-01:latest'], stdout=subprocess.PIPE)
out, err = processCopilot.communicate()
d = json.loads(out)
if d['accepted'] == False:
    processCopilot = subprocess.Popen(['az','vm', 'image', 'terms', 'accept', '--urn', 'aviatrix-systems:aviatrix-copilot:avx-cplt-byol-01:latest'], stdout=subprocess.PIPE)