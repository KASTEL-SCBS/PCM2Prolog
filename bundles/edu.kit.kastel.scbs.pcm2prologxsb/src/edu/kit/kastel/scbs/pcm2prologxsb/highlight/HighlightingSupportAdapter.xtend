/** 
 * Copyright (c) 2011 committers of YAKINDU and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * Contributors:
 * committers of YAKINDU - initial API and implementation
 */
package edu.kit.kastel.scbs.pcm2prologxsb.highlight
import java.lang.reflect.Method
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.draw2d.IFigure
import org.eclipse.emf.ecore.EObject
import org.eclipse.gmf.runtime.diagram.ui.editparts.IGraphicalEditPart
import org.eclipse.gmf.runtime.diagram.ui.editparts.IPrimaryEditPart
import org.eclipse.gmf.runtime.diagram.ui.figures.BorderedNodeFigure
import org.eclipse.gmf.runtime.diagram.ui.parts.IDiagramWorkbenchPart
import org.eclipse.gmf.runtime.diagram.ui.resources.editor.parts.DiagramDocumentEditor
import org.eclipse.gmf.runtime.gef.ui.figures.DefaultSizeNodeFigure
import org.eclipse.swt.graphics.Color
import org.eclipse.swt.widgets.Display
/** 
 * @author Alexander Nyssen
 * @author Andreas Muelder
 * @author Axel Terfloth
 */
class HighlightingSupportAdapter implements IHighlightingSupport{
	/* FIXME Non-static inner classes are not supported.*/private static class ColorMemento {
		final Color foregroundColor
		final Color backgroundColor
		final IFigure figure
		protected  new(IFigure figure) {
			this.figure=figure 
			this.foregroundColor=figure.getForegroundColor() 
			this.backgroundColor=figure.getBackgroundColor() 
		}
		def protected void restore() {
			figure.setForegroundColor(foregroundColor) 
			figure.setBackgroundColor(backgroundColor) 
		}// restore all elements still being highlighted
		
	}
	final Map<IFigure, ColorMemento> figureStates=new HashMap<IFigure, ColorMemento>()
	boolean locked=false
	final IDiagramWorkbenchPart diagramWorkbenchPart
	Map<EObject, IGraphicalEditPart> object2editPart=new HashMap<EObject, IGraphicalEditPart>()
	 new(IDiagramWorkbenchPart diagramWorkbenchPart) {
		this.diagramWorkbenchPart=diagramWorkbenchPart 
	}
	def private IGraphicalEditPart getEditPartForSemanticElement(EObject semanticElement) {
		var IGraphicalEditPart result=object2editPart.get(semanticElement) 
		if (result !== null) return result 
		result=EditPartUtils.findEditPartForSemanticElement(diagramWorkbenchPart.getDiagramGraphicalViewer().getRootEditPart(), semanticElement) 
		object2editPart.put(semanticElement, result) 
		return result 
	}
	def private IFigure getTargetFigure(IGraphicalEditPart editPart) {
		var IFigure figure=editPart.getFigure() 
		if (figure instanceof BorderedNodeFigure) {
			figure=figure.getChildren().get(0) as IFigure 
		}
		if (figure instanceof DefaultSizeNodeFigure) {
			figure=figure.getChildren().get(0) as IFigure 
		}
		return figure 
	}
	override synchronized void lockEditor() {
		if (locked) {
			throw new IllegalStateException("Editor already locked!")
		}
		var List<Action> singletonList=new ArrayList() 
		singletonList.add([IHighlightingSupport hs|lockEditorInternal() ]) 
		executeSync(singletonList) 
	}
	def private void lockEditorInternal() {
		setSanityCheckEnablementState(false) 
		for (Object editPart : diagramWorkbenchPart.getDiagramGraphicalViewer().getEditPartRegistry().values()) {
			if (editPart instanceof IPrimaryEditPart) {
				var IGraphicalEditPart graphicalEditPart=(editPart as IGraphicalEditPart) 
				var IFigure figure=getTargetFigure(graphicalEditPart) 
				figureStates.put(figure, new ColorMemento(figure)) 
			}
		}
		locked=true 
	}
	def private void setSanityCheckEnablementState(boolean state) {
		try {
			var Method enableMethod=DiagramDocumentEditor.getDeclaredMethod("enableSanityChecking", #[boolean]) 
			enableMethod.setAccessible(true) 
			enableMethod.invoke(diagramWorkbenchPart, #[state]) 
		} catch (Exception e) {
			e.printStackTrace() 
		}
		
	}
	override synchronized void releaseEditor() {
		if (!locked) {
			throw new IllegalStateException("Editor not locked!")
		}
		var List<Action> singletonList=new ArrayList() 
		singletonList.add([IHighlightingSupport hs|releaseInternal() ]) 
		executeSync(singletonList) 
	}
	def protected void releaseInternal() {
		for (ColorMemento figureState : figureStates.values()) {
			figureState.restore() 
		}
		figureStates.clear() 
		diagramWorkbenchPart.getDiagramEditPart().enableEditMode() 
		setSanityCheckEnablementState(true) 
		object2editPart.clear() 
		locked=false 
	}
	override void highlight(List<? extends EObject> semanticElements, HighlightingParameters parameters) {
		synchronized (semanticElements) {
			for (EObject semanticElement : semanticElements) {
				var IGraphicalEditPart editPartForSemanticElement=getEditPartForSemanticElement(semanticElement) 
				if (editPartForSemanticElement !== null) {
					var IFigure figure=getTargetFigure(editPartForSemanticElement) 
					if (parameters !== null) {
						figure.setForegroundColor(parameters.foregroundFadingColor) 
						figure.setBackgroundColor(parameters.backgroundFadingColor) 
						figure.invalidate() 
					} else {
						var ColorMemento memento=figureStates.get(figure) 
						if (memento !== null) memento.restore() 
					}
				}
			}
		}
	}
	override boolean isLocked() {
		return locked 
	}
	override void executeAsync(List<Action> actions) {
		if (actions !== null) {
			Display.getDefault().asyncExec([for (Action a : actions) {
				a.execute(HighlightingSupportAdapter.this) 
			}]) 
		}
	}
	def protected void executeSync(List<Action> actions) {
		if (actions !== null) {
			Display.getDefault().syncExec([for (Action a : actions) {
				a.execute(HighlightingSupportAdapter.this) 
			}]) 
		}
	}
}