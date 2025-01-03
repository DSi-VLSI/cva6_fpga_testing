//Copyright (C) 2018 to present,
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 08.02.2018
// Migrated: Luis Vitorio Cargnini, IEEE
// Date: 09.06.2018

// return address stack
`include "macros.sv"

module ras #(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type ras_t = logic,
    parameter int unsigned DEPTH = 2
) (
    // Subsystem Clock - SUBSYSTEM
    input logic clk_i,
    // Asynchronous reset active low - SUBSYSTEM
    input logic rst_ni,
    // Branch prediction flush request - zero
    input logic flush_bp_i,
    // Push address in RAS - FRONTEND
    input logic push_i,
    // Pop address from RAS - FRONTEND
    input logic pop_i,
    // Data to be pushed - FRONTEND
    input logic [CVA6Cfg.VLEN-1:0] data_i,
    // Popped data - FRONTEND
    output ras_t data_o
);

  // ras_t [DEPTH-1:0] stack_d, stack_q;

  ras_t  stack_d [DEPTH];
  ras_t  stack_q [DEPTH];


  // assign data_o = stack_q[0];
  assign data_o.ra = stack_q[0].ra;
  assign data_o.valid = stack_q[0].valid;

  always_comb begin
    // stack_d = stack_q;
    // for (int i = 0; i < DEPTH; i++) begin
    //   stack_d[i] = stack_q[i];
    // end
    `EQUAL_CONT(stack_d, stack_q, DEPTH)


    // push on the stack
    if (push_i) begin
      stack_d[0].ra = data_i;
      // mark the new return address as valid
      stack_d[0].valid = 1'b1;
      // stack_d[DEPTH-1:1] = stack_q[DEPTH-2:0];
      for (int i = DEPTH - 1; i > 0; i--) begin
        stack_d[i] = stack_q[i-1];
      end
    end

    if (pop_i) begin
      // stack_d[DEPTH-2:0] = stack_q[DEPTH-1:1];
      for (int i = DEPTH - 2; i >= 0; i--) begin
        stack_d[i] = stack_q[i+1];
      end

      // we popped the value so invalidate the end of the stack
      stack_d[DEPTH-1].valid = 1'b0;
      stack_d[DEPTH-1].ra = 'b0;
    end
    // leave everything untouched and just push the latest value to the
    // top of the stack
    if (pop_i && push_i) begin
      // stack_d = stack_q;
      for (int i = 0; i < DEPTH; i++) begin
        stack_d[i] = stack_q[i];
      end

      stack_d[0].ra = data_i;
      stack_d[0].valid = 1'b1;
    end

    if (flush_bp_i) begin
      // stack_d = '0;
      for (int i = 0; i < DEPTH; i++) begin
        stack_d[i] = '0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      // stack_q <= '0;
      // stack_q <= '{default: '0}; // Struct initialization
      for (int i = 0; i < DEPTH; i++) begin
        stack_q[i] <= '0;
      end
    end else begin

      // stack_q <= stack_d;
      for (int i = 0; i < DEPTH; i++) begin
        stack_q[i] <= stack_d[i];
      end

    end
  end
endmodule
