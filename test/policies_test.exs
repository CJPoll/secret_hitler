defmodule SecretHitler.GameBuilder.Test do
  use ExUnit.Case

  @test_module SecretHitler.GameBuilder

  describe "liberal_count/1" do
    test "works correctly" do
      assert 3 = @test_module.liberal_count(5)
      assert 4 = @test_module.liberal_count(6)
      assert 4 = @test_module.liberal_count(7)
      assert 5 = @test_module.liberal_count(8)
      assert 5 = @test_module.liberal_count(9)
      assert 6 = @test_module.liberal_count(10)
      assert 6 = @test_module.liberal_count(11)
    end
  end

  describe "fascist_count/1" do
    test "works correctly" do
      assert 2 = @test_module.fascist_count(5)
      assert 2 = @test_module.fascist_count(6)
      assert 3 = @test_module.fascist_count(7)
      assert 3 = @test_module.fascist_count(8)
      assert 4 = @test_module.fascist_count(9)
      assert 4 = @test_module.fascist_count(10)
      assert 5 = @test_module.fascist_count(11)
    end
  end
end
