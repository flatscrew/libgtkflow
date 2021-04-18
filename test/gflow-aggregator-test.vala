using GFlow;

public class GFlowTest.AggregatorTest {
    public static void add_tests() {
        Test.add_func("/gflow/aggregator/array-attributes",
            () => {

                var new_flow_id = "test";

                var aggregator = Aggregator.get_instance();
                var pipeline = aggregator.new_aggregation_pipeline(new_flow_id);

                pipeline.set_array_attribute_at_index("test", "value1", 0);
                pipeline.set_array_attribute_at_index("test", "value2", 1);
                pipeline.set_array_attribute_at_index("test", "value3", 2);

                pipeline.commit(new TestPredicate(), pipeline => {
                    var list = pipeline.get_array_attribute("test");
                    assert(list.length == 3);
                    return true;
                });
            });
    }

    public class TestPredicate : AggregationPredicate, Object {

        public bool should_commit (GFlow.AggregationPipeline aggregation_pipeline) {
            return aggregation_pipeline.get_array_attribute("test").length == 3;
        }
    }
}
