Installation Notes
==================
This is an example of how to use this module in PandoraFMS

In an agent config file ( /etc/pandorafms/pandora_agent.conf for linux)

<br>module_begin
<br>module_name <desctriptive name: include address for refference>
<br>module_type generic_data
<br>module_exec bash </path/to/sctript.sh> <website.to.check>
<br>module_description Find how many days are left on SSL Cert.
<br>module_end

Restart agent service. New module will display on next agent contact interval.
