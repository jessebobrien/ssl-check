Installation Notes
==================
This is an example of how to use this module in PandoraFMS

In an agent config file ( /etc/pandorafms/pandora_agent.conf for linux)

module_begin
module_name <desctriptive name: include address for refference>
module_type generic_data
module_exec bash </path/to/sctript.sh> <website.to.check>
module_description Find how many days are left on SSL Cert.
module_end

Restart agent service. New module will display on next agent contact interval.
