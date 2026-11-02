package org.geogebra.plus.course;

import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.geogebra.common.main.App;
import org.geogebra.common.plugin.GgbAPI;
import org.geogebra.plus.course.CourseAction.Directive;
import org.geogebra.plus.course.CourseNode.Kind;

/** Native SWT course tree shown only when a course file is selected. */
public final class CourseTreePanel extends Composite {

    private final CourseModel course;
    private final Tree tree;
    private final Text description;
    private final Label status;
    private final Button runButton;
    private final Button checkButton;
    private final Button nextButton;
    private final List<TreeItem> steps = new ArrayList<>();
    private final DirectiveExecutor executor;

    public CourseTreePanel(Composite parent, CourseModel course, Path courseFile,
            GgbAPI api2d, GgbAPI api3d, App app2d, App app3d) throws IOException {
        super(parent, SWT.NONE);
        this.course = course;
        setLayout(new GridLayout(1, false));
        this.executor = new DirectiveExecutor(getDisplay(), courseFile, api2d, api3d, app2d, app3d);

        Label heading = new Label(this, SWT.WRAP);
        heading.setText(course.getCourse());
        heading.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));

        tree = new Tree(this, SWT.SINGLE | SWT.BORDER | SWT.V_SCROLL | SWT.H_SCROLL);
        tree.setLayoutData(new GridData(SWT.FILL, SWT.FILL, true, true));
        for (CourseNode chapter : course.getTree()) {
            addNode(tree, null, chapter);
        }
        tree.addListener(SWT.Selection, event -> updateSelection());

        description = new Text(this, SWT.MULTI | SWT.WRAP | SWT.READ_ONLY | SWT.BORDER | SWT.V_SCROLL);
        GridData descriptionData = new GridData(SWT.FILL, SWT.CENTER, true, false);
        descriptionData.heightHint = 72;
        description.setLayoutData(descriptionData);

        Composite buttons = new Composite(this, SWT.NONE);
        buttons.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
        buttons.setLayout(new GridLayout(4, true));
        runButton = button(buttons, "Run");
        checkButton = button(buttons, "Check");
        nextButton = button(buttons, "Next");
        Button resetButton = button(buttons, "Reset");
        runButton.addListener(SWT.Selection, event -> runSelected());
        checkButton.addListener(SWT.Selection, event -> checkSelected());
        nextButton.addListener(SWT.Selection, event -> selectNext());
        resetButton.addListener(SWT.Selection, event -> resetProgress());

        status = new Label(this, SWT.WRAP);
        status.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
        status.setText("Progress checks are formative only; WIMS owns grading.");
        updateSelection();
    }

    private void addNode(Composite parent, TreeItem parentItem, CourseNode node) {
        TreeItem item = parentItem == null ? new TreeItem(tree, SWT.NONE) : new TreeItem(parentItem, SWT.NONE);
        item.setText(node.title());
        item.setData(node);
        if (node.kind() == Kind.STEP) {
            steps.add(item);
        }
        for (CourseNode child : node.children()) {
            addNode(parent, item, child);
        }
    }

    private static Button button(Composite parent, String title) {
        Button button = new Button(parent, SWT.PUSH);
        button.setText(title);
        button.setLayoutData(new GridData(SWT.FILL, SWT.CENTER, true, false));
        return button;
    }

    private void updateSelection() {
        CourseNode selected = selectedStep();
        if (selected == null) {
            description.setText(course.getDescription().isBlank()
                    ? "Select a step to see its instructions." : course.getDescription());
            runButton.setEnabled(false);
            checkButton.setEnabled(false);
            nextButton.setEnabled(false);
            return;
        }
        description.setText(selected.description());
        runButton.setEnabled(!selected.actions().isEmpty());
        checkButton.setEnabled(selected.check() != null);
        TreeItem selectedItem = tree.getSelection()[0];
        nextButton.setEnabled(steps.indexOf(selectedItem) >= 0
                && steps.indexOf(selectedItem) < steps.size() - 1);
    }

    private CourseNode selectedStep() {
        TreeItem[] selected = tree.getSelection();
        if (selected.length == 0 || !(selected[0].getData() instanceof CourseNode node)
                || node.kind() != Kind.STEP) {
            return null;
        }
        return node;
    }

    private void runSelected() {
        CourseNode step = selectedStep();
        if (step == null) {
            return;
        }
        if (!confirmUnscannedTrustedFiles(step)) {
            status.setText("Cancelled before opening the explicitly trusted .ggb file.");
            return;
        }
        setBusy(true);
        executor.runAsync(step, (success, message) -> finish(success, message));
    }

    private boolean confirmUnscannedTrustedFiles(CourseNode step) {
        List<CourseAction> trustedOpens = step.actions().stream()
                .filter(action -> action.directive() == Directive.OPEN && action.trustedGgb())
                .toList();
        if (trustedOpens.isEmpty()) {
            return true;
        }
        String names = trustedOpens.stream().map(CourseAction::value).reduce((left, right) -> left + "\n" + right)
                .orElse("(file name unavailable)");
        MessageBox warning = new MessageBox(getShell(), SWT.ICON_WARNING | SWT.OK | SWT.CANCEL);
        warning.setText("Trusted GeoGebra files are not scanned");
        warning.setMessage("This course explicitly trusts the following .ggb file(s), but this build has no script "
                + "scanner. Embedded JavaScript or object scripts may execute when a file opens. Continue only if "
                + "you trust the course author and files:\n\n" + names);
        return warning.open() == SWT.OK;
    }

    private void checkSelected() {
        CourseNode step = selectedStep();
        if (step == null) {
            return;
        }
        setBusy(true);
        executor.checkAsync(step, (success, message) -> finish(success, message));
    }

    private void selectNext() {
        TreeItem[] selected = tree.getSelection();
        if (selected.length == 0) {
            return;
        }
        int index = steps.indexOf(selected[0]);
        if (index >= 0 && index + 1 < steps.size()) {
            TreeItem next = steps.get(index + 1);
            for (TreeItem parent = next.getParentItem(); parent != null; parent = parent.getParentItem()) {
                parent.setExpanded(true);
            }
            tree.setSelection(next);
            tree.showItem(next);
            updateSelection();
        }
    }

    private void resetProgress() {
        status.setText("Course progress reset. The GeoGebra construction was not changed.");
        if (!steps.isEmpty()) {
            TreeItem first = steps.get(0);
            for (TreeItem parent = first.getParentItem(); parent != null; parent = parent.getParentItem()) {
                parent.setExpanded(true);
            }
            tree.setSelection(first);
            tree.showItem(first);
        } else {
            tree.deselectAll();
        }
        updateSelection();
    }

    private void setBusy(boolean busy) {
        runButton.setEnabled(!busy && selectedStep() != null && !selectedStep().actions().isEmpty());
        checkButton.setEnabled(!busy && selectedStep() != null && selectedStep().check() != null);
        nextButton.setEnabled(!busy && nextButton.isEnabled());
        tree.setEnabled(!busy);
        status.setText(busy ? "Running on the GeoGebra UI thread…" : status.getText());
    }

    private void finish(boolean success, String message) {
        if (isDisposed()) {
            return;
        }
        status.setText((success ? "Done: " : "Not completed: ") + message);
        tree.setEnabled(true);
        updateSelection();
    }
}
