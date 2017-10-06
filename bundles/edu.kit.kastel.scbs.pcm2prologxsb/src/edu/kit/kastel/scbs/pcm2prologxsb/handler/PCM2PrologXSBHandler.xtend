package edu.kit.kastel.scbs.pcm2prologxsb.handler

import org.eclipse.core.resources.IFile
import edu.kit.ipd.sdq.mdsd.ecore2txt.util.Ecore2TxtUtil
import edu.kit.ipd.sdq.mdsd.ecore2log.config.UserConfiguration
import edu.kit.ipd.sdq.mdsd.ecore2log.handler.AbstractEcore2LogHandler
import edu.kit.kastel.scbs.pcm2prologxsb.generator.PCM2PrologXSBGenerator
import edu.kit.kastel.scbs.pcm2prologxsb.generator.PCM2PrologXSBGeneratorModule
import edu.kit.kastel.scbs.pcm2prologxsb.verifier.PCM2PrologJIVerifier
import java.util.List
import edu.kit.kastel.scbs.pcm2prologxsb.highlight.ElementsHighlight
import java.util.concurrent.Callable
import com.ugos.jiprolog.engine.JIPEngine

class PCM2PrologXSBHandler extends AbstractEcore2LogHandler {

	override executeEcore2TxtGenerator(List<IFile> files, UserConfiguration userConfiguration) {
		var generator=new PCM2PrologXSBGenerator(userConfiguration);
		val generatedPrologFiles=Ecore2TxtUtil.generateFromSelectedFilesInFolder(files,new PCM2PrologXSBGeneratorModule(),generator, userConfiguration.concatOutputToSingleFile(), userConfiguration.groupFacts())
		if(userConfiguration.runJIProlog()){
		val highlighter = new ElementsHighlight();
		var verifier = new PCM2PrologJIVerifier(generator.getIDMap(),generator.getEObjectsWithID(),highlighter);
		var generatedFilesStream=verifier.createGeneratedPrologFilesInputStream(generatedPrologFiles);
		verifier.start(generatedFilesStream);
	}
	}
	override getPlugInID() '''edu.kit.kastel.scbs.pcm2prologxsb'''
}