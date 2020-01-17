package edu.kit.kastel.scbs.pcm2prologxsb.commandLineInterpretation;

import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.cli.Parser;

public class PCM2PrologxsbCLI {
	
	private PCM2PrologxsbCLIHandler cliHandler;
	
	public PCM2PrologxsbCLI() {
		cliHandler = new PCM2PrologxsbCLIHandler();
	}
	
	
	private CommandLine parseInput(Options options, String[] args) throws ParseException {
		CommandLineParser parser = new BasicParser();
		return parser.parse(options, args);
	}
	
	public PCM2PrologXSBCommandLineContent interrogateCommandLine(String[] args) {
		Options options = cliHandler.getOptions();
		CommandLine cmd = null;
		try {
			cmd = parseInput(options, args);
		} catch (ParseException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return cliHandler.interrogateCommandLine(cmd);
		
	}
	
}
