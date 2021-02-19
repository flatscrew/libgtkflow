// Compile: $ valac minimal.vala --pkg gtk+-3.0 --pkg gflow-0.6 --pkg gtkflow-0.6

using Gtk;
using GFlow;

public class NumberGeneratorNode : GFlow.SimpleNode {

    private GFlow.SimpleSource number_source;
    private Gtk.SpinButton spin_button;

    public NumberGeneratorNode() {
        number_source = new GFlow.SimpleSource.with_type(Type.DOUBLE);
        number_source.name = "output";
        
        spin_button = new Gtk.SpinButton(new Gtk.Adjustment(0, 0, 100, 1, 10, 0), 0, 0);
        spin_button.set_size_request(50,20);
        spin_button.value_changed.connect(() => {
            number_source.set_value(spin_button.get_value());
        });

        name = "NumberGenerator";
        add_source(number_source);
    }

    public void add_to_view(GtkFlow.NodeView view) {
        view.add_with_child(this, spin_button);
    }
}

public class OperationNode : GFlow.SimpleNode {

    private double operand_a_value = 0;
    private double operand_b_value = 0;
    private string operation = "";

    private GFlow.SimpleSink summand_a;
    private GFlow.SimpleSink summand_b;

    private GFlow.SimpleSource result;
    private Gtk.ComboBoxText combobox;

    public OperationNode() {
        summand_a = new GFlow.SimpleSink.with_type(Type.DOUBLE);
        summand_a.name = "operand A";
        summand_a.changed.connect(value => {
            if (value == null) {
                return;
            }
            operand_a_value = value.get_double();
            publish_result();
        });
        add_sink(summand_a);

        summand_b = new GFlow.SimpleSink.with_type(Type.DOUBLE);
        summand_b.name = "operand B";
        summand_b.changed.connect(value => {
            if (value == null) {
                return;
            }
            operand_b_value = value.get_double();
            publish_result();
        });
        add_sink(summand_b);

        result = new GFlow.SimpleSource(Type.DOUBLE);
        result.name = "result";
        add_source(result);

        string[] operations = {"+", "-", "*", "/"};
        combobox = new Gtk.ComboBoxText();
        combobox.changed.connect(() => {
            operation = combobox.get_active_text();
        });
        combobox.set_entry_text_column(0);
        foreach (var operation in operations) {
            combobox.append_text(operation);
        }
        name = "Operation";
    }

    private void publish_result() {
        if (operation == "+") {
            set_result(operand_a_value + operand_b_value);
        } else if (operation == "-") {
            set_result(operand_a_value - operand_b_value);
        } else if (operation == "*") {
            set_result(operand_a_value * operand_b_value);
        } else if (operation == "/") {
            set_result(operand_a_value / operand_b_value);
        }
    }

    private void set_result(double operation_result) {
        print("setting result > %f\n", operation_result);
        result.set_value(operation_result);
    }

    public void add_to_view(GtkFlow.NodeView view) {
        view.add_with_child(this, combobox);
    }
}

public class PrintNode : GFlow.SimpleNode {

    private GFlow.SimpleSink number;
    private Gtk.Label childlabel;

    public PrintNode() {
        number = new GFlow.SimpleSink.with_type(Type.DOUBLE);
        number.name = "input";
        number.changed.connect(display_value);

        childlabel = new Gtk.Label("");

        name = "Output";
        add_sink(number);
    }

    public void add_to_view(GtkFlow.NodeView view) {
        view.add_with_child(this, childlabel);
    }

    private void display_value(Value? value) {
        if (value == null) {
            return;
        }
        childlabel.set_text(value.strdup_contents());
    }
}

public class AdvancedCalculatorWindow : Gtk.Window {

    construct {
        set_default_size(400, 300);
        destroy.connect(Gtk.main_quit);
    }

    private Gtk.HeaderBar header_bar;
    private GtkFlow.NodeView node_view;

    public AdvancedCalculatorWindow() {
        init_header_bar();
        init_window_layout();
        init_actions();
    }

    private void init_header_bar() {
        header_bar = new HeaderBar();
        header_bar.show_close_button = true;
        header_bar.title = "Advaned calculator demo";
        set_titlebar(header_bar);
    }

    private void init_window_layout() {
        var scrolled_window = new ScrolledWindow(null, null);
        node_view = new GtkFlow.NodeView();
        scrolled_window.add(node_view);
        add(scrolled_window);
    }

    private void init_actions() {
        add_number_node_action();
        add_operation_node_action();
        add_print_node_action();
    }

    private void add_number_node_action() {
        var button = new Gtk.Button.with_label("NumberGenerator");
        button.clicked.connect(() => {
            var node = new NumberGeneratorNode();
            node.add_to_view(node_view);
        });
        header_bar.add(button);
    }

    private void add_operation_node_action() {
        var button = new Gtk.Button.with_label("Operation");
        button.clicked.connect(() => {
            var node = new OperationNode();
            node.add_to_view(node_view);
        });
        header_bar.add(button);
    }

    private void add_print_node_action() {
        var button = new Gtk.Button.with_label("Print");
        button.clicked.connect(() => {
            var node = new PrintNode();
            node.add_to_view(node_view);
        });
        header_bar.add(button);
    }
}

public void main(string[] args) {
    Gtk.init(ref args);
    var window = new AdvancedCalculatorWindow();
    window.show_all();
    Gtk.main();
}
