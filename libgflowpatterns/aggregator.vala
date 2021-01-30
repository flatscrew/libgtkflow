namespace GFlowPatterns {

    public class Aggregator {
        
        private Gee.Map<string, AggregationPipeline?> _pipelines = new Gee.HashMap<string, AggregationPipeline?>();
        private static Aggregator _instance;

        private Aggregator() {}

        public static Aggregator get_instance() {
            if (_instance == null) {
                _instance = new Aggregator();
            }
            return _instance;
        }

        public AggregationPipeline new_aggregation_pipeline(string id) {
            var new_pipeline = new AggregationPipeline(id);
            new_pipeline.pipeline_commit.connect(commit_pipeline); 
            _pipelines.set(id, new_pipeline);
            return new_pipeline;
        }

        private void commit_pipeline(string id) {
            _pipelines.unset(id);
        }

        public AggregationPipeline? find_aggregation_pipeline(string? id) {
            if (id == null) {
                return null;
            }
            return _pipelines.get(id);
        }
    }

    public interface AggregationPredicate : Object {

        public abstract bool should_commit(AggregationPipeline aggregation_pipeline);
    }

    public class AggregationPipeline : Object {

        public signal void pipeline_commit(string id);
        public delegate bool PipelineDelegate(AggregationPipeline pipeline);

        private Gee.Map<string, Value?> _attributes = new Gee.HashMap<string, Value?>();
        private Gee.Map<string, ValuesArray> _indexed_attributes = new Gee.HashMap<string, ValuesArray>();
        
        public string id { 
            public get; 
            construct set; 
        }

        public AggregationPipeline(string id) {
            Object(id: id);
        }

        public AggregationPipeline set_attribute(string name, Value? value) {
            _attributes.set(name, value);
            return this;
        }

        public Value? get_attribute(string name) {
            return _attributes.get(name);
        }

        public AggregationPipeline set_array_attribute(string name, Value? value) {
            return set_array_attribute_at_index(name, value, 0);
        }

        public AggregationPipeline set_array_attribute_at_index(string name, Value? value, int index) {
            var list = _indexed_attributes.get(name);
            if (list == null) {
                list = new ValuesArray();
                _indexed_attributes.set(name, list);
            }
            list.insert(index, value);
            return this;
        }

        public Value?[]? get_array_attribute(string name) {
            var list = _indexed_attributes.get(name);
            if (list == null) {
                return null;
            }
            return list.to_array();
        }

        public bool has_attribute(string name) {
            return _attributes.has_key(name) || _indexed_attributes.has_key(name);
        }

        public void commit(AggregationPredicate aggregation_predicate, PipelineDelegate pipeline_delegate) {
            if (!aggregation_predicate.should_commit(this)) {
                return;
            }
            if (pipeline_delegate(this)) {
                pipeline_commit(id);
                _attributes.clear();
                _indexed_attributes.clear();
            }
        }
    }

    public class ValuesArray : Object {

        private Gee.Map<uint, Value?> _array = new Gee.HashMap<uint, Value?>();
    
        public void insert(uint index, Value? value) {
            _array.set(index, value);
        }
        
        public Value? get_value(uint index) {
            return _array.get(index);
        }

        public Value?[] to_array() {
            return _array.values.to_array();
        }
    }
}