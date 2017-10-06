package edu.kit.kastel.scbs.pcm2prologxsb.highlight

import org.eclipse.gmf.runtime.diagram.ui.parts.IDiagramWorkbenchPart
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.draw2d.ColorConstants
import org.eclipse.swt.graphics.Color
import org.eclipse.ui.PlatformUI

class ElementsHighlight {
	private IDiagramWorkbenchPart diagramWorkbenchPart
	private IHighlightingSupport objectsHighlighter
	private HighlightingParameters colorParameters
	
	new (){
        this.diagramWorkbenchPart= PlatformUI.getWorkbench().getActiveWorkbenchWindow().getActivePage().getActiveEditor() as IDiagramWorkbenchPart;
		this.objectsHighlighter=new HighlightingSupportAdapter(this.diagramWorkbenchPart);
		this.colorParameters=new HighlightingParameters(ColorConstants.red,new Color(null, 255, 128, 128))
	}
	
	public def highlightObjects(List<EObject> objectsToHighlight){
		objectsHighlighter.highlight(objectsToHighlight,colorParameters)
	}
}
//https://stackoverflow.com/questions/9348767/how-to-get-active-editor-in-eclipse-plugin
//https://github.com/Yakindu/statecharts/blob/e9a3c18a7199412aca6cd62421546353441650dc/plugins/org.yakindu.sct.simulation.ui/src/org/yakindu/sct/simulation/ui/model/presenter/SCTSourceDisplay.java